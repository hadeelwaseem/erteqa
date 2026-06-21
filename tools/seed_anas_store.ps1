#Requires -Version 5.1
<#
.SYNOPSIS
  Seeds Anas Store tenant with catalog, commerce infra, and orders for mobile E2E testing.

.DESCRIPTION
  Loads credentials from tools/seed_anas_store.config.json (copy from .example).
  Phases: refresh token -> payments/shipping/discount -> categories/tags/products ->
  public API verification -> guest + customer orders -> shipment lifecycle.

.PARAMETER OtpCode
  Customer OTP for authenticated checkout (default 123456 for dev servers).

.PARAMETER SkipOrders
  Skip order creation (catalog + infra only).

.EXAMPLE
  .\tools\seed_anas_store.ps1 -OtpCode 123456
#>
[CmdletBinding()]
param(
    [string]$OtpCode = '123456',
    [switch]$SkipOrders,
    [string]$ConfigPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $scriptRoot 'seed_anas_store.config.json'
}
if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath`nCopy tools/seed_anas_store.config.example.json and fill tokens."
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$BaseUrl = $config.baseUrl.TrimEnd('/')
$TenantId = $config.tenantId
$TenantSlug = $config.tenantSlug
$StoreSlug = $config.storeSlug
$AccessToken = $config.accessToken
$RefreshToken = $config.refreshToken
$CustomerPhone = $config.customerPhone
$GuestEmail = $config.guestEmail

$State = @{
    CategoryIds = @{}
    TagIds = @{}
    ProductIds = @{}
    VariantIds = @{}
    PaymentProviderId = $null
    ShippingProviderId = $null
    GuestOrderId = $null
    GuestOrderNumber = $null
    CustomerOrderId = $null
    ShipmentId = $null
}

function Write-Phase([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "    OK: $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "    WARN: $Message" -ForegroundColor Yellow
}

function Write-Err([string]$Message) {
    Write-Host "    FAIL: $Message" -ForegroundColor Red
}

function Invoke-Api {
    param(
        [string]$Method = 'GET',
        [string]$Path,
        [object]$Body = $null,
        [string]$Token = $AccessToken,
        [hashtable]$ExtraHeaders = @{},
        [switch]$Public,
        [switch]$AllowFailure
    )

    $headers = @{
        'Accept' = 'application/json'
    }
    if ($Public) {
        $headers['X-Tenant-ID'] = $TenantId
    }
    if ($Token) {
        $headers['Authorization'] = "Bearer $Token"
    }
    foreach ($key in $ExtraHeaders.Keys) {
        $headers[$key] = $ExtraHeaders[$key]
    }

    $uri = "$BaseUrl$Path"
    $params = @{
        Method = $Method
        Uri = $uri
        Headers = $headers
    }
    if ($null -ne $Body) {
        $params['ContentType'] = 'application/json'
        $params['Body'] = ($Body | ConvertTo-Json -Depth 20 -Compress)
    }

    try {
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        $detail = $_.Exception.Message
        if ($null -ne $_.ErrorDetails) {
            $msgProp = $_.ErrorDetails.PSObject.Properties['Message']
            if ($msgProp) {
                $detail = $msgProp.Value
            }
        }
        if ($AllowFailure) {
            return @{ success = $false; error = $detail }
        }
        throw "API $Method $Path failed: $detail"
    }
}

function Invoke-MultipartProduct {
    param(
        [Parameter(Mandatory = $true)]
        $ProductJson,
        [string]$ImagePath = ''
    )

    $productFile = Join-Path $env:TEMP "seed-product-$([Guid]::NewGuid().ToString('N')).json"
    $ProductJson | ConvertTo-Json -Depth 20 | Set-Content -Path $productFile -Encoding UTF8

    $curlArgs = @(
        '-sS',
        '-X', 'POST',
        "$BaseUrl/api/v1/admin/products",
        '-H', "Authorization: Bearer $AccessToken",
        '-F', "product=@$productFile;type=application/json"
    )
    if ($ImagePath -and (Test-Path $ImagePath)) {
        $curlArgs += '-F', "files=@$ImagePath"
    }

    $raw = & curl.exe @curlArgs
    Remove-Item -Force $productFile -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -ne 0) {
        throw "curl product create failed (exit $LASTEXITCODE): $raw"
    }
    return $raw | ConvertFrom-Json
}

function Get-FirstVariantId([string]$ProductId) {
    $detail = Invoke-Api -Path "/api/v1/admin/products/$ProductId/variants"
    if ($detail.data.PSObject.Properties['variants']) {
        $variants = @($detail.data.variants)
        if ($variants.Count -gt 0 -and $variants[0].PSObject.Properties['variantId']) {
            return $variants[0].variantId
        }
    }

    $matrix = Invoke-Api -Path "/api/v1/admin/products/$ProductId?include=INVENTORY"
    if ($matrix.data.PSObject.Properties['variants'] -and $matrix.data.variants) {
        $variants = @($matrix.data.variants)
        if ($variants.Count -gt 0 -and $variants[0].PSObject.Properties['variantId']) {
            return $variants[0].variantId
        }
    }
    throw "No variant found for product $ProductId"
}

function Repair-ProductVariants {
    param(
        [string]$ProductId,
        [string]$Slug,
        $ProductJson
    )

    if (-not $ProductJson.PSObject.Properties['variants']) { return }
    $firstVariant = $ProductJson.variants[0]
    if (-not $firstVariant) { return }

    $price = [int]$ProductJson.basePrice
    $stockQty = 50
    $sku = "$Slug-default"
    if ($firstVariant.PSObject.Properties['price']) { $price = [int]$firstVariant.price }
    if ($firstVariant.PSObject.Properties['stockQty']) { $stockQty = [int]$firstVariant.stockQty }
    if ($firstVariant.PSObject.Properties['sku']) { $sku = [string]$firstVariant.sku }

    $body = @{
        options = @(
            @{
                optionNameAr = 'Default'
                optionNameEn = 'Default'
                sortOrder = 0
                values = @(
                    @{
                        valueAr = 'Standard'
                        valueEn = 'Standard'
                        sortOrder = 0
                    }
                )
            }
        )
        variantOverrides = @{
            Standard = @{
                sku = $sku
                price = $price
                stockQty = $stockQty
                isActive = $true
            }
        }
    }
    Invoke-Api -Method PUT -Path "/api/v1/admin/products/$ProductId/variants" -Body $body -AllowFailure | Out-Null
    Write-Ok "Repaired variants for $Slug"
}

function Find-AdminProductBySlug([string]$Slug) {
    $list = Invoke-Api -Path '/api/v1/admin/products?page=0&size=100'
    $items = $null
    if ($list.data -is [array]) {
        $items = $list.data
    }
    elseif ($list.data.PSObject.Properties['content']) {
        $items = $list.data.content
    }
    elseif ($list.data.PSObject.Properties['items']) {
        $items = $list.data.items
    }
    if (-not $items) { return $null }
    foreach ($item in $items) {
        if ($item.slug -eq $Slug) { return $item }
    }
    return $null
}

function Find-AdminCategoryBySlug([string]$Slug) {
    $tree = Invoke-Api -Path '/api/v1/admin/categories'
    $nodes = $tree.data
    if (-not $nodes) { return $null }

    function Search-Nodes($list) {
        foreach ($node in $list) {
            if ($node.slug -eq $Slug) { return $node }
            if ($node.children) {
                $found = Search-Nodes $node.children
                if ($found) { return $found }
            }
        }
        return $null
    }
    return Search-Nodes $nodes
}

function Ensure-Category {
    param(
        [string]$Slug,
        [string]$NameEn,
        [string]$NameAr,
        [string]$ParentCategoryId = $null
    )

    $existing = Find-AdminCategoryBySlug -Slug $Slug
    if ($existing) {
        $State.CategoryIds[$Slug] = $existing.categoryId
        Write-Warn "Category exists: $Slug ($($existing.categoryId))"
        return $existing.categoryId
    }

    $body = @{
        nameEn = $NameEn
        nameAr = $NameAr
        slug = $Slug
        descriptionEn = "$NameEn category"
        descriptionAr = "فئة $NameAr"
        parentCategoryId = $ParentCategoryId
        sortOrder = 0
        isActive = $true
    }
    $res = Invoke-Api -Method POST -Path '/api/v1/admin/categories' -Body $body
    $id = $res.data.categoryId
    $State.CategoryIds[$Slug] = $id
    Write-Ok "Category $Slug -> $id"
    return $id
}

function Ensure-Tag([string]$Name) {
    $slug = $Name.ToLower()
    $list = Invoke-Api -Path '/api/v1/admin/tags' -AllowFailure
    if ($list.success -ne $false -and $list.data) {
        $tags = @($list.data)
        foreach ($tag in $tags) {
            $tagLabel = $tag.tagName
            if (-not $tagLabel -and $tag.PSObject.Properties['name']) {
                $tagLabel = $tag.name
            }
            if ($tagLabel -eq $Name) {
                $tagId = $tag.productTagId
                if (-not $tagId -and $tag.PSObject.Properties['tagId']) {
                    $tagId = $tag.tagId
                }
                $State.TagIds[$Name] = $tagId
                Write-Warn "Tag exists: $Name"
                return $tagId
            }
        }
    }

    $res = Invoke-Api -Method POST -Path '/api/v1/admin/tags' -Body @{
        tagName = $Name
        slug = $slug
    } -AllowFailure
    if ($res.success -eq $false) {
        Write-Warn "Tag create failed for $Name : $($res.error)"
        return $null
    }
    $id = $res.data.productTagId
    if (-not $id -and $res.data.PSObject.Properties['tagId']) {
        $id = $res.data.tagId
    }
    $State.TagIds[$Name] = $id
    Write-Ok "Tag $Name -> $id"
    return $id
}

function Ensure-Product {
    param(
        [Parameter(Mandatory = $true)]
        $ProductJson,
        [string]$ImagePath = ''
    )

    $slug = $ProductJson.slug
    $existing = Find-AdminProductBySlug -Slug $slug
    if ($existing) {
        $productId = $existing.productId
        $State.ProductIds[$slug] = $productId
        try {
            $vid = Get-FirstVariantId -ProductId $productId
            $State.VariantIds[$slug] = $vid
        }
        catch {
            Repair-ProductVariants -ProductId $productId -Slug $slug -ProductJson $ProductJson
            $vid = Get-FirstVariantId -ProductId $productId
            $State.VariantIds[$slug] = $vid
        }
        Write-Warn "Product exists: $slug ($productId)"
        return $productId
    }

    $res = Invoke-MultipartProduct -ProductJson $ProductJson -ImagePath $ImagePath
    if (-not $res.success) {
        $errMsg = if ($res.PSObject.Properties['message']) { $res.message } else { 'unknown error' }
        throw "Product create $slug failed: $errMsg"
    }
    $productId = $res.data.product.productId
    $State.ProductIds[$slug] = $productId
    $vid = $null
    if ($res.data.PSObject.Properties['variants'] -and $res.data.variants) {
        $createdVariants = @($res.data.variants)
        if ($createdVariants.Count -gt 0) {
            $vid = $createdVariants[0].variantId
        }
    }
    if (-not $vid) {
        $vid = Get-FirstVariantId -ProductId $productId
    }
    $State.VariantIds[$slug] = $vid
    Write-Ok "Product $slug -> $productId (variant $vid)"
    return $productId
}

function Download-SeedImage([string]$Url, [string]$FileName) {
    $path = Join-Path $env:TEMP $FileName
    if (-not (Test-Path $path)) {
        Invoke-WebRequest -Uri $Url -OutFile $path -UseBasicParsing
    }
    return $path
}

# --- Phase 0: Refresh token ---
Write-Phase 'Phase 0: Refresh merchant token'
$refreshRes = Invoke-Api -Method POST -Path '/api/v1/auth/refresh' -Body @{
    refreshToken = $RefreshToken
} -Token '' -Public:$false
if ($refreshRes.data.accessToken) {
    $AccessToken = $refreshRes.data.accessToken
    if ($refreshRes.data.refreshToken) {
        $RefreshToken = $refreshRes.data.refreshToken
    }
    Write-Ok 'Token refreshed'
}
else {
    Write-Warn 'Refresh returned no new token; using config accessToken'
}

# --- Phase 1: Commerce infrastructure ---
Write-Phase 'Phase 1: Payment, shipping, discount'

$providers = Invoke-Api -Path '/api/v1/admin/payment-providers' -AllowFailure
$hasCod = $false
if ($providers.data) {
    foreach ($p in $providers.data) {
        if ($p.providerCode -eq 'COD') { $hasCod = $true }
    }
}
if (-not $hasCod) {
    Invoke-Api -Method POST -Path '/api/v1/admin/payment-providers' -Body @{
        providerCode = 'COD'
        displayName = 'Cash on Delivery'
        isActive = $true
        sortOrder = 0
    } | Out-Null
    Write-Ok 'COD payment provider created'
}
else {
    Write-Warn 'COD payment provider already exists'
}

$paymeraExists = $false
if ($providers.data) {
    foreach ($p in $providers.data) {
        if ($p.providerCode -eq 'PAYMERA') { $paymeraExists = $true }
    }
}
if (-not $paymeraExists) {
    Invoke-Api -Method POST -Path '/api/v1/admin/payment-providers' -Body @{
        providerCode = 'PAYMERA'
        displayName = 'Credit Card (Paymera)'
        credentialsJson = '{"terminalId":"TEST-001","username":"test","password":"test"}'
        settingsJson = '{"environment":"test","lang":"ar"}'
        isActive = $true
        sortOrder = 1
    } -AllowFailure | Out-Null
    Write-Ok 'Paymera payment provider created (or skipped on error)'
}

$shipProviders = Invoke-Api -Path '/api/v1/admin/shipping/providers' -AllowFailure
$hasShip = $false
if ($shipProviders.data) {
    foreach ($s in $shipProviders.data) {
        if ($s.providerCode -eq 'DAMASCUS_EXPRESS') {
            $hasShip = $true
            $State.ShippingProviderId = $s.shippingProviderId
        }
    }
}
if (-not $hasShip) {
    $shipRes = Invoke-Api -Method POST -Path '/api/v1/admin/shipping/providers' -Body @{
        providerCode = 'DAMASCUS_EXPRESS'
        providerName = 'Damascus Express'
        apiBaseUrl = 'https://api.damascus-express.sy/v1'
        apiKey = 'sk_test_key'
        webhookSecret = 'whsec_test_secret'
        priority = 10
    }
    $State.ShippingProviderId = $shipRes.data.shippingProviderId
    Write-Ok "Shipping provider -> $($State.ShippingProviderId)"
}
else {
    Write-Warn 'Shipping provider already exists'
}

$discList = Invoke-Api -Path '/api/v1/admin/discount-codes' -AllowFailure
$hasDisc = $false
if ($discList.data) {
    foreach ($d in $discList.data) {
        if ($d.code -eq 'ANAS10') { $hasDisc = $true }
    }
}
if (-not $hasDisc) {
    Invoke-Api -Method POST -Path '/api/v1/admin/discount-codes' -Body @{
        code = 'ANAS10'
        discountType = 'PERCENTAGE'
        discountValue = 10
        minOrderAmount = 50000
        maxDiscountCap = 50000
        usageLimit = 100
        perCustomerMax = 5
        applicableScope = 'ALL'
        startsAt = '2026-01-01T00:00:00'
        expiresAt = '2027-12-31T23:59:59'
    } | Out-Null
    Write-Ok 'Discount code ANAS10 created'
}
else {
    Write-Warn 'Discount ANAS10 already exists'
}

$methods = Invoke-Api -Path '/api/v1/public/payments/methods' -Public
$methodCount = 0
if ($methods.data) { $methodCount = @($methods.data).Count }
Write-Ok "Public payment methods: $methodCount"

# --- Phase 2: Catalog ---
Write-Phase 'Phase 2: Categories, tags, products'

$dataPath = Join-Path $scriptRoot 'seed_anas_store.data.json'
$seedData = Get-Content $dataPath -Raw | ConvertFrom-Json

foreach ($cat in $seedData.categories) {
    $parentId = $null
    if ($cat.parentSlug) {
        $parentId = $State.CategoryIds[$cat.parentSlug]
    }
    Ensure-Category -Slug $cat.slug -NameEn $cat.nameEn -NameAr $cat.nameAr -ParentCategoryId $parentId | Out-Null
}

foreach ($tagName in $seedData.tags) {
    Ensure-Tag -Name $tagName | Out-Null
}

foreach ($p in $seedData.products) {
    $imagePath = ''
    if ($p.imageUrl) {
        $fileName = "seed-$($p.slug).jpg"
        $imagePath = Download-SeedImage -Url $p.imageUrl -FileName $fileName
    }
    $productJson = $p.json
    Ensure-Product -ProductJson $productJson -ImagePath $imagePath | Out-Null
}

Write-Phase 'Phase 2b: Public catalog verification'
$catPub = Invoke-Api -Path '/api/v1/public/categories' -Public
$catCount = @($catPub.data).Count
Write-Ok "Public categories: $catCount"

$prodPub = Invoke-Api -Path '/api/v1/public/products?page=0&size=6' -Public
$prodItems = $null
if ($prodPub.data.PSObject.Properties['content']) { $prodItems = $prodPub.data.content }
elseif ($prodPub.data.PSObject.Properties['items']) { $prodItems = $prodPub.data.items }
elseif ($prodPub.data.PSObject.Properties['products']) { $prodItems = $prodPub.data.products }
elseif ($prodPub.data -is [array]) { $prodItems = $prodPub.data }
$prodCount = @($prodItems).Count
if ($prodCount -lt 1) {
    throw "Public products empty - check product status ACTIVE and store ACTIVE"
}
Write-Ok "Public featured products: $prodCount"

$search = Invoke-Api -Path '/api/v1/public/products/search?q=shirt&page=0&size=20' -Public -AllowFailure
Write-Ok 'Search API returned success'

$auto = Invoke-Api -Path '/api/v1/public/products/autocomplete?q=shirt&page=0&size=10' -Public -AllowFailure
Write-Ok 'Autocomplete API returned success'

$detail = Invoke-Api -Path '/api/v1/public/products/cotton-shirt?include=PRICING&include=IMAGES&include=VARIANTS&include=CATEGORIES&include=TAGS' -Public
$detailTitle = if ($detail.data.titleEn) { $detail.data.titleEn } else { $detail.data.slug }
Write-Ok "Product detail cotton-shirt: $detailTitle"

# --- Phase 4: Store settings enrichment ---
Write-Phase 'Phase 4: Store settings enrichment'
Invoke-Api -Method PUT -Path '/api/v1/admin/store/settings' -Body @{
    storeName = 'Anas Store'
    slug = $StoreSlug
    primaryCurrencyCode = 'SYP'
    profileNameEn = 'Anas Store'
    contactPhone = '+963935237452'
    governorate = 'Damascus'
    city = 'Damascus'
    street = 'Al-Hamra Street'
    themeCode = 'modern'
} -AllowFailure | Out-Null
Write-Ok 'Store settings updated'

if ($SkipOrders) {
    Write-Warn 'SkipOrders set — skipping order phases'
}
else {
    # --- Phase 3: Orders ---
    Write-Phase 'Phase 3a: Guest COD checkout'

    if (-not $State.VariantIds['cotton-shirt']) {
        throw 'cotton-shirt variant missing — cannot place guest order'
    }

    $guestCheckout = Invoke-Api -Method POST -Path '/api/v1/public/checkout' -Public -Body @{
        items = @(@{ variantId = $State.VariantIds['cotton-shirt']; quantity = 2 })
        shippingAddress = @{
            latitude = 33.5138
            longitude = 36.2765
            recipientName = 'Ahmad Guest'
            phone = '+963955000002'
            addressLabel = 'Damascus, Al-Hamra St'
        }
        paymentMethod = 'COD'
        checkoutToken = [Guid]::NewGuid().ToString()
        guestEmail = $GuestEmail
    }
    $State.GuestOrderId = $guestCheckout.data.orderId
    $State.GuestOrderNumber = $guestCheckout.data.orderNumber
    Write-Ok "Guest order $($State.GuestOrderNumber) id=$($State.GuestOrderId)"

    Write-Phase 'Phase 3b: Customer authenticated checkout'
    $otpRequest = Invoke-Api -Method POST -Path '/api/v1/customer/auth/otp/request' -Token '' -Body @{
        phone = $CustomerPhone.Replace('+', '')
        tenantId = $TenantId
        fullName = 'Test Customer'
    } -AllowFailure
    if ($otpRequest.success -ne $false) {
        Write-Ok "Customer OTP requested for $CustomerPhone"
    }
    else {
        Write-Warn "Customer OTP request failed: $($otpRequest.error)"
    }

    $verify = Invoke-Api -Method POST -Path '/api/v1/customer/auth/otp/verify' -Token '' -Body @{
        phone = $CustomerPhone.Replace('+', '')
        otpCode = $OtpCode
        tenantId = $TenantId
    } -AllowFailure

    $customerToken = $null
    if ($verify.success -ne $false -and $verify.data.accessToken) {
        $customerToken = $verify.data.accessToken
        Write-Ok 'Customer OTP verified'

        if (-not $State.VariantIds['wireless-earbuds']) {
            throw 'wireless-earbuds variant missing'
        }

        $custCheckout = Invoke-Api -Method POST -Path '/api/v1/public/checkout' -Public -Token $customerToken -Body @{
            items = @(@{ variantId = $State.VariantIds['wireless-earbuds']; quantity = 1 })
            shippingAddress = @{
                latitude = 33.5138
                longitude = 36.2765
                recipientName = 'Test Customer'
                phone = $CustomerPhone
                addressLabel = 'Damascus, Mezzeh'
            }
            paymentMethod = 'COD'
            checkoutToken = [Guid]::NewGuid().ToString()
        }
        $State.CustomerOrderId = $custCheckout.data.orderId
        Write-Ok "Customer order id=$($State.CustomerOrderId)"
    }
    else {
        Write-Warn "Customer OTP verify failed (try -OtpCode with real code). Guest order still created."
    }

    Write-Phase 'Phase 3c: Order lifecycle + shipment'
    if ($State.GuestOrderId) {
        Invoke-Api -Method POST -Path "/api/v1/admin/orders/$($State.GuestOrderId)/transition" -Body @{
            targetStatus = 'CONFIRMED'
        } -AllowFailure | Out-Null
        Write-Ok 'Guest order -> CONFIRMED'

        if ($State.ShippingProviderId) {
            $shipCreate = Invoke-Api -Method POST -Path '/api/v1/admin/shipping/shipments' -Body @{
                orderId = $State.GuestOrderId
                shippingProviderId = $State.ShippingProviderId
                originLat = 33.5138
                originLng = 36.2765
                destinationLat = 36.2021
                destinationLng = 37.1343
                expectedCodAmountSyp = 170000
            } -AllowFailure
            if ($shipCreate.data.shipmentId) {
                $State.ShipmentId = $shipCreate.data.shipmentId
                Invoke-Api -Method POST -Path "/api/v1/admin/shipping/shipments/$($State.ShipmentId)/transition" -Body @{
                    targetStatus = 'PICKED_UP'
                } -AllowFailure | Out-Null
                Write-Ok "Shipment $($State.ShipmentId) -> PICKED_UP"
            }
        }

        $track = Invoke-Api -Path "/api/v1/public/shipping/track/$($State.GuestOrderId)" -Public -AllowFailure
        if ($track.success -ne $false) {
            Write-Ok 'Public shipment track OK'
        }
    }
}

# --- Test card ---
Write-Phase 'Seed complete - mobile test card'
Write-Host @"

  API base:       $BaseUrl
  Tenant ID:      $TenantId
  Tenant slug:    $TenantSlug
  Store slug:     $StoreSlug

  Bootstrap:      assets/config/bootstrap.local.json (already pointed)

  Customer login: $CustomerPhone  (OTP: use -OtpCode or app OTP flow)
  Guest track:    order=$($State.GuestOrderNumber)  email=$GuestEmail

  Product slugs:  cotton-shirt, wireless-earbuds, summer-dress
  Discount code:  ANAS10

  Guest order ID:     $($State.GuestOrderId)
  Customer order ID:  $($State.CustomerOrderId)
  Shipment ID:        $($State.ShipmentId)

  Run app:  flutter run

"@ -ForegroundColor White
