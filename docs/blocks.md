# Erteqa Block & Component Documentation

This document is the single source of truth for the Erteqa (SOOQ) visual editor. It covers pages, system settings, all blocks with their props and field types, the layout system, shared field helpers, data fixtures, and theme presets.

## 1. Pages Structure

Defined in `config/pages.ts`. Pages are registered in a typed array:

| Path | Label | Icon | Dynamic | Description |
|---|---|---|---|---|
| `/` | Home | `Home` | No | Main landing page |
| `/themes` | Theme gallery | `Palette` | No | Browse and edit theme presets |
| `/products/:product-slug` | Product Details | `Package` | **Yes** | Individual product page |
| `/cart` | Cart | `ShoppingCart` | No | Shopping cart & checkout |

**Custom pages** are stored in `localStorage` under key `puck-demo-custom-pages:v1`. Merchants can create additional pages at runtime. Dynamic pages use `examplePath` for editing (e.g. `/products/example-product`).

**Page data** is initialized per-path via `config/initial-data.ts`, which maps each path to its starter `UserData` JSON.

---

## 2. System Settings (Root Config)

File: `config/root.tsx`. These are site-wide props available in the Settings panel.

### 2.1 Locale (direction/language/currency)

| Prop | Type | Default | Options |
|---|---|---|---|
| `direction` | `"rtl" \| "ltr"` | `"rtl"` | — |
| `language` | `"ar" \| "en"` | `"ar"` | — |
| `currency` | `"SYP" \| "USD" \| "EUR"` | `"SYP"` | — |

### 2.2 Page Metadata

| Prop | Type | Default |
|---|---|---|
| `title` | `string` | `"SOOQ — متجر"` |
| `enableHtmlRichTextBlock` | `boolean` | `false` |

### 2.3 Fonts (Theme)

| Prop | Type | Default | Options |
|---|---|---|---|
| `bodyFont` | `string` | `"dm-sans"` | All [`FONT_OPTIONS`](#32-font-options) values |
| `fontOption1` | `string` | `"space-grotesk"` | All font option values |
| `fontOption2` | `string` | `"fraunces"` | All font option values |

### 2.4 Colors

| Prop | Type | Default | Description |
|---|---|---|---|
| `primary` | `string` (hex) | `#0b78c5` | Brand / action color |
| `surface` | `string` (hex) | `#f6f8fc` | Card & panel backgrounds |
| `success` | `string` (hex) | `#0f9d73` | Positive feedback |
| `warning` | `string` (hex) | `#c77a15` | Caution / alerts |
| `error` | `string` (hex) | `#c24133` | Destructive / danger |
| `dark` | `string` (hex) | `#10213a` | Dark backgrounds |
| `text` | `string` (hex) | `#14243f` | Default body text |
| `neutral` | `string` (hex) | `#6b7d93` | Borders, dividers, muted |

### 2.5 Badge (shared component)

| Prop | Type | Default | Options |
|---|---|---|---|
| `badgeShape` | `"pill" \| "rounded" \| "square"` | `"rounded"` | — |
| `badgeStyle` | `"solid" \| "outline" \| "soft"` | `"solid"` | — |

### 2.6 Shell (header/footer variant)

| Prop | Type | Default | Options |
|---|---|---|---|
| `headerVariant` | `"default" \| "commerce"` | `"commerce"` | — |
| `footerVariant` | `"default" \| "commerce"` | `"commerce"` | — |

### 2.7 Breakpoints (responsive visibility)

| Prop | Type | Default | Description |
|---|---|---|---|
| `breakpointMobileMax` | `number` (px) | `767` | Inclusive max for "mobile" |
| `breakpointTabletMax` | `number` (px) | `1023` | Inclusive max for "tablet" |

### 2.8 Typography Scales

| Prop | Type | Default | Description |
|---|---|---|---|
| `textSizeXs` | `string` | `"0.75rem"` | — |
| `textSizeSm` | `string` | `"0.875rem"` | — |
| `textSizeMd` | `string` | `"1rem"` | — |
| `textSizeLg` | `string` | `"1.1875rem"` | — |
| `textSizeXl` | `string` | `"1.375rem"` | — |
| `textSize2xl` | `string` | `"1.75rem"` | — |
| `radiusNone` | `string` | `"0"` | — |
| `radiusSm` | `string` | `"8px"` | — |
| `radiusMd` | `string` | `"12px"` | — |
| `radiusLg` | `string` | `"18px"` | — |
| `radiusXl` | `string` | `"24px"` | — |
| `radiusFull` | `string` | `"9999px"` | — |
| `buttonSmHeight` | `string` | `"34px"` | — |
| `buttonSmPaddingX` | `string` | `"14px"` | — |
| `buttonSmPaddingY` | `string` | `"6px"` | — |
| `buttonSmFontSize` | `string` | `"0.875rem"` | — |
| `buttonMdHeight` | `string` | `"44px"` | — |
| `buttonMdPaddingX` | `string` | `"18px"` | — |
| `buttonMdPaddingY` | `string` | `"9px"` | — |
| `buttonMdFontSize` | `string` | `"1rem"` | — |
| `buttonLgHeight` | `string` | `"54px"` | — |
| `buttonLgPaddingX` | `string` | `"26px"` | — |
| `buttonLgPaddingY` | `string` | `"12px"` | — |
| `buttonLgFontSize` | `string` | `"1.0625rem"` | — |
| `fontWeightNormal` | `string` | `"400"` | — |
| `fontWeightMedium` | `string` | `"520"` | — |
| `fontWeightSemibold` | `string` | `"620"` | — |
| `fontWeightBold` | `string` | `"740"` | — |
| `lineHeightTight` | `string` | `"1.22"` | — |
| `lineHeightNormal` | `string` | `"1.58"` | — |
| `lineHeightRelaxed` | `string` | `"1.78"` | — |

### 2.9 Shell: Header

| Prop | Type | Default | Description |
|---|---|---|---|
| `headerVisible` | `boolean` | `true` | Show/hide site-wide header |
| `headerBrandHref` | `string` | `"/"` | Brand/logo link target |
| `headerBrandTitle` | `string` | (empty) | Brand text override |
| `headerLinks` | `HeaderLink[]` | see defaults | Nav items (bilingual) |
| `headerBackgroundColor` | `string` (hex) | `""` (theme default) | — |
| `headerTextColor` | `string` (hex) | `""` (theme default) | — |
| `headerShowDrawerButton` | `boolean` | `false` | Hamburger toggle for drawer |
| `headerDrawerButtonIcon` | `"menu" \| "x"` | `"menu"` | — |

### 2.10 Shell: Footer

| Prop | Type | Default | Description |
|---|---|---|---|
| `footerVisible` | `boolean` | `true` | Show/hide site-wide footer |
| `footerTagline` | `string` | `""` | Short tagline (EN) |
| `footerTaglineAr` | `string` | `""` | Short tagline (AR) |
| `footerBrandTitle` | `string` | `""` | Brand text override |
| `footerColumns` | `FooterColumn[]` | see defaults | Link columns (bilingual) |
| `footerBackgroundColor` | `string` (hex) | `""` | — |
| `footerTextColor` | `string` (hex) | `""` | — |

### 2.11 Shell: Site Drawer

| Prop | Type | Default | Options |
|---|---|---|---|
| `drawerEnabled` | `boolean` | `false` | Master switch |
| `drawerSide` | `"left" \| "right"` | `"left"` | — |
| `drawerWidthPx` | `number` | `320` | Panel width (min 200) |
| `drawerAnimation` | `"slide" \| "fade" \| "slide-fade"` | `"slide"` | — |
| `drawerAnimationDurationMs` | `number` | `260` | — |
| `drawerTrigger` | `"external" \| "icon" \| "both"` | `"external"` | How drawer opens |
| `drawerTriggerLabel` | `string` | `"Menu"` | — |
| `drawerTriggerLabelAr` | `string` | `"القائمة"` | — |
| `drawerTriggerIcon` | `"menu" \| "x" \| "panel-left" \| "panel-right"` | `"menu"` | — |
| `drawerTitle` | `string` | `"Menu"` | — |
| `drawerTitleAr` | `string` | `"القائمة"` | — |
| `drawerShowTitle` | `boolean` | `true` | — |
| `drawerLinks` | `SiteDrawerLink[]` | see defaults | — |
| `drawerBackgroundColor` | `string` (hex) | `"#ffffff"` | — |
| `drawerTextColor` | `string` (hex) | `"#111827"` | — |
| `drawerAccentColor` | `string` (hex) | `"#2563eb"` | — |
| `drawerTriggerBackgroundColor` | `string` (hex) | `"#ffffff"` | — |
| `drawerTriggerTextColor` | `string` (hex) | `"#111827"` | — |
| `drawerOverlay` | `boolean` | `true` | Show backdrop |
| `drawerOverlayOpacityPercent` | `number` (0–100) | `50` | — |
| `drawerCloseOnOverlayClick` | `boolean` | `true` | — |
| `drawerCloseOnEsc` | `boolean` | `true` | — |
| `drawerShowCloseButton` | `boolean` | `true` | — |
| `drawerStartOpen` | `boolean` | `false` | — |
| `drawerShowOnMobile` | `boolean` | `true` | — |
| `drawerShowOnDesktop` | `boolean` | `true` | — |

---

## 3. Theme & Design Tokens

### 3.1 CSS Variable Architecture

All theme values are exposed as CSS custom properties on the `.theme-root` element:

**Color vars:** `--theme-color-{key}` (e.g. `--theme-color-primary`, `--theme-color-text`)

**Derived vars** (computed from colors):
- `--theme-color-background` — page background (surface 88% + white)
- `--theme-color-surface` — card/panel bg
- `--theme-color-surface-elevated`
- `--theme-color-border` — neutral 34% + white
- `--theme-color-muted`
- `--theme-color-text-muted`
- `--theme-color-primaryMuted` — primary 15% + white
- `--theme-color-primaryHover` — primary 84% + black
- `--theme-color-on-primary` — white
- `--theme-color-onPrimary` — white
- `--theme-color-focusRing`

**Scale vars:** `--theme-text-size-{step}`, `--theme-radius-{step}`, `--theme-button-{size}-{dimension}`, `--theme-font-weight-{step}`, `--theme-line-height-{step}`

**Font vars:** `--theme-body-font`, `--theme-font-1`, `--theme-font-2`

**Badge vars:** `--theme-badge-radius`, `--theme-badge-padding-x`, `--theme-badge-padding-y`, `--theme-badge-font-size`, `--theme-badge-font-weight`, `--theme-badge-{type}-{bg,fg,border}` (types: `discount`, `stock`, `out`)

### 3.2 Font Options

| Value | CSS Font |
|---|---|
| `system` | `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif` |
| `inter` | `'Inter', sans-serif` |
| `roboto` | `'Roboto', sans-serif` |
| `open-sans` | `'Open Sans', sans-serif` |
| `lato` | `'Lato', sans-serif` |
| `poppins` | `'Poppins', sans-serif` |
| `montserrat` | `'Montserrat', sans-serif` |
| `raleway` | `'Raleway', sans-serif` |
| `nunito` | `'Nunito', sans-serif` |
| `dm-sans` | `'DM Sans', sans-serif` |
| `manrope` | `'Manrope', sans-serif` |
| `sora` | `'Sora', sans-serif` |
| `playfair-display` | `'Playfair Display', Georgia, serif` |
| `merriweather` | `'Merriweather', Georgia, serif` |
| `lora` | `'Lora', Georgia, serif` |
| `space-grotesk` | `'Space Grotesk', sans-serif` |
| `geist` | `'Geist', sans-serif` |
| `fraunces` | `'Fraunces', serif` |

### 3.3 Component Font Options

Selectable on blocks: `"body"` (= `var(--theme-body-font)`), `"option1"` (= `var(--theme-font-1)`), `"option2"` (= `var(--theme-font-2)`).

### 3.4 Shared Spacing

File: `config/options.ts`. `spacingOptions` = 8px through 160px in 8px steps (20 options).

### 3.5 Theme Presets

File: `config/theme-presets.ts`.

| Preset | ID | Font | Colors |
|---|---|---|---|
| **Atelier** | `atelier` | body: Merriweather, option1: Playfair Display, option2: Raleway | primary: `#9f1239`, surface: `#faf7f5`, warm neutrals |

Presets override the full `FullThemeProps` shape. Each preset has a demo page at `/themes/{id}`.

---

## 4. Layout System

Every block can optionally include a `layout` prop drawn from `LayoutFieldProps`. The layout system provides:

### 4.1 Grid Spanning

| Prop | Type | Default |
|---|---|---|
| `spanCol` | `number` | `1` |
| `spanRow` | `number` | `1` |
| `grow` | `boolean` | `false` |

### 4.2 Spacing (Margin & Padding)

| Prop | Type | Default |
|---|---|---|
| `padding` (deprecated) | `string` | `"0px"` |
| `paddingTop` | `string` | `"0px"` |
| `paddingRight` | `string` | `"0px"` |
| `paddingBottom` | `string` | `"0px"` |
| `paddingLeft` | `string` | `"0px"` |
| `marginTop` | `string` | `"0px"` |
| `marginRight` | `string` | `"0px"` |
| `marginBottom` | `string` | `"0px"` |
| `marginLeft` | `string` | `"0px"` |

### 4.3 Float / Positioning

| Prop | Type | Default | Options |
|---|---|---|---|
| `positionMode` | `"static" \| "float"` | `"static"` | — |
| `floatUseFixedPosition` | `boolean` | `true` | `fixed` vs `absolute` |
| `floatPlacementMode` | `"custom" \| "preset"` | `"preset"` | — |
| `floatPreset` | (8 anchors) | `"top-left"` | `top-left`, `top-middle`, `top-right`, `middle-left`, `middle-right`, `bottom-left`, `bottom-middle`, `bottom-right` |
| `fixedTop` / `fixedRight` / `fixedBottom` / `fixedLeft` | `string` | `"auto"` | `auto` or 0%–100% in 5% steps |

### 4.4 Border

| Prop | Type | Default | Options |
|---|---|---|---|
| `borderWidth` | `string` | `"0px"` | — |
| `borderStyle` | `"solid" \| "dashed" \| "none"` | `"solid"` | — |
| `borderColor` | `string` | `"#cbd5e1"` | — |

### 4.5 Box Shadow

| Prop | Type | Default | Options |
|---|---|---|---|
| `shadowMode` | `"none" \| "preset" \| "custom"` | `"none"` | — |
| `shadowPreset` | `"sm" \| "md" \| "lg" \| "xl"` | `"md"` | — |
| `shadowOffsetX` / `shadowOffsetY` | `string` | `"0px"` / `"4px"` | — |
| `shadowBlur` | `string` | `"6px"` | — |
| `shadowSpread` | `string` | `"0px"` | — |
| `shadowColor` | `string` | `"rgba(0, 0, 0, 0.12)"` | — |

### 4.6 Display & Visibility

| Prop | Type | Default | Options |
|---|---|---|---|
| `displayMode` | `"block" \| "flex" \| "grid"` | `"block"` | — |
| `hideOnMobile` | `boolean` | `false` | Hides at <= `breakpointMobileMax` |
| `hideOnTablet` | `boolean` | `false` | Hides at `mobile+1` to `tabletMax` |
| `hideOnDesktop` | `boolean` | `false` | Hides at >= `tabletMax+1` |

### 4.7 Layout in Puck

The root `render` wraps content in:

```
[Shell Left Zone] [DropZone (SiteHeader, Section, SiteFooter)] [Shell Right Zone]
```

Shell zones are 56px editing rails (hidden on live site), accepting `SiteDrawerShell` blocks.

---

## 5. Blocks

Blocks are registered in `config/blocks/<Name>/index.tsx`. Each exports a Puck `ComponentConfig` with:
- `fields` — field definitions (text, number, radio, select, custom, external, array, object)
- `defaultProps` — default values
- `render` — React component
- Optional `blockRules` (allowed children for Section, Flex, Grid, Group)

### 5.1 Layout Blocks

#### Section

The outermost container. Accepts child blocks in its `content` Slot.

| Field | Label | Type | Default | Options / Notes |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | Unique identifier |
| `paddingTop` | Padding top | `select` | `"0px"` | `spacingOptions` |
| `paddingBottom` | Padding bottom | `select` | `"0px"` | `spacingOptions` |
| `paddingHorizontal` | Padding horizontal | `select` | `"0px"` | `spacingOptions` |
| `maxWidth` | Max width | `text` | `"1280px"` | CSS max-width value |
| `backgroundColor` | Background color | `text` | `""` | Fixed hex or empty (inherit) |
| `theme` | Theme mode | `radio` | `"light"` | `"light"` \| `"dark"` |

**Slot:** `content` — allows any block.

#### Flex

Flexbox container with `items` array of child blocks.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `direction` | Direction | `radio` | `"row"` | `"row"` \| `"column"` |
| `justifyContent` | Justify | `select` | `"flex-start"` | `flex-start`, `center`, `flex-end`, `space-between`, `space-around` |
| `alignItems` | Align | `select` | `"stretch"` | `flex-start`, `center`, `flex-end`, `stretch`, `baseline` |
| `wrap` | Wrap | `radio` | `"nowrap"` | `"nowrap"` \| `"wrap"` |
| `gap` | Gap | `select` | `8` | 4, 8, 12, 16, 20, 24, 28, 32 |

**Slot:** `items` — array blocks (each item is a child block).

#### Grid

Grid container with `items` array of child blocks.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `numColumns` | Columns | `radio` | `2` | 2, 3, 4 |
| `gap` | Gap | `select` | `16` | 4–32 in 4px steps |

**Slot:** `items` — array blocks.

#### Group

Multi-child wrapper with inline `content` slots (like a strip).

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `direction` | Direction | `radio` | `"column"` | `"row"` \| `"column"` |
| `alignItems` | Align items | `select` | `"flex-start"` | `flex-start`, `center`, `flex-end`, `stretch` |
| `justifyContent` | Justify | `select` | `"flex-start"` | `flex-start`, `center`, `flex-end`, `space-between`, `space-around` |
| `wrap` | Wrap | `radio` | `"nowrap"` | `"nowrap"` \| `"wrap"` |
| `gap` | Gap | `select` | `8` | 4–32 in 4px steps |

**Slot:** `content` — allows any block.

---

### 5.2 Content Blocks

#### Heading

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `text` | Text | `text` | `"Heading"` | Rich text (TipTap) |
| `level` | Level | `radio` | `"2"` | `"1"`, `"2"`, `"3"`, `"4"` |
| `align` | Alignment | `radio` | `"center"` | `"left"`, `"center"`, `"right"` |
| `size` | Size | `radio` | `"xl"` | `"md"`, `"lg"`, `"xl"`, `"xxl"` (or `"xs"`, `"sm"` for some blocks) |
| `fontFamily` | Font | `select` | `"body"` | `"body"`, `"option1"`, `"option2"` |
| `colorMode` | Color mode | `radio` | `"theme"` | `"theme"` \| `"fixed"` |
| `colorTheme` | Theme color | `select` | `"text"` | All `ColorKey` values |
| `colorFixed` | Fixed color | `custom` | `"#0f172a"` | Color picker + hex input |

**Typography helpers** (shared): Mode toggle (`theme`/`fixed`), text size step selector (xs–2xl), radius step selector (none–full), font weight (normal–bold), line height (tight–relaxed). See `config/content/typography-fields.ts`.

#### Text (paragraph body)

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `text` | Text | `richtext` | `"Text content..."` | TipTap rich text |
| `align` | Alignment | `radio` | `"left"` | `"left"`, `"center"`, `"right"` |
| `size` | Size | `radio` | `"m"` | `"s"`, `"m"`, `"l"` |
| `color` | Color | `radio` | `"default"` | `"default"` \| `"muted"` |
| `fontFamily` | Font | `select` | `"body"` | `"body"`, `"option1"`, `"option2"` |

#### Paragraph (legacy — same as Text)

Deprecated alias for Text.

#### Space

Empty spacer block.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `size` | Size | `select` | `"16px"` | `spacingOptions` (8px–160px) |
| `direction` | Direction | `radio` | `"vertical"` | `"vertical"` \| `"horizontal"` |

#### Button

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `label` | Label | `text` | `"Button"` | — |
| `labelAr` | Label (Arabic) | `text` | `""` | — |
| `buttonAction` | Action | `radio` | `"link"` | `link`, `login`, `logout`, `addToCart`, `addToWishlist` |
| `href` | URL | `text` | `""` | — |
| `link` | Link | `object` | — | Sub-fields: `kind` (`page` \| `url`), `pageId`, `url`, `newWindow: boolean` |
| `variant` | Variant | `radio` | `"primary"` | `"primary"`, `"secondary"`, `"outline"`, `"ghost"`, `"danger"` |
| `size` | Size | `radio` | `"md"` | `"sm"`, `"md"`, `"lg"` |
| `fullWidth` | Full width | `radio` | `"off"` | `"on"` \| `"off"` |
| `fontFamily` | Font | `select` | `"body"` | Font options |
| `colorMode` | Color mode | `radio` | `"theme"` | `"theme"` \| `"fixed"` |
| `colorTheme` | Theme color | `select` | `"primary"` | ColorKey values |
| `colorFixed` | Fixed color | `custom` | `"#0f172a"` | Color picker + hex |

#### Link

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `label` | Label | `text` | `"Link"` | — |
| `labelAr` | Label (Arabic) | `text` | `""` | — |
| `href` | URL | `text` | `""` | — |
| `link` | Link | `object` | — | `kind`, `pageId`, `url`, `newWindow` |
| `variant` | Variant | `radio` | `"default"` | `"default"`, `"muted"`, `"accent"` |

#### Icon

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `name` | Icon name | `text` | `"Star"` | Any Lucide icon name |
| `size` | Size | `select` | `"24"` | `"16"`, `"20"`, `"24"`, `"32"`, `"40"`, `"48"` |
| `colorMode` | Color mode | `radio` | `"theme"` | `"theme"` \| `"fixed"` |
| `colorTheme` | Theme color | `select` | `"text"` | ColorKey values |
| `colorFixed` | Fixed color | `custom` | `"#0f172a"` | Color picker + hex |
| `strokeWidth` | Stroke width | `select` | `"2"` | `"1"`, `"1.5"`, `"2"`, `"2.5"`, `"3"` |

#### Image

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `src` | Image URL | `text` | Unsplash placeholder | — |
| `alt` | Alt text | `text` | `""` | Accessibility |
| `aspectRatio` | Aspect ratio | `radio` | `"auto"` | `"auto"`, `"square"`, `"landscape"`, `"portrait"`, `"wide"` |
| `borderRadius` | Radius | `select` | `"md"` | `none`, `sm`, `md`, `lg`, `xl`, `full` |
| `shadow` | Shadow | `select` | `"none"` | `none`, `sm`, `md`, `lg`, `xl` |
| `objectFit` | Object fit | `select` | `"cover"` | `cover`, `contain`, `fill`, `none` |
| `width` | Width | `text` | `"100%"` | CSS value |
| `height` | Height | `text` | `"auto"` | CSS value |

#### Video

Embeds a video player with custom poster.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `src` | Video URL | `text` | `""` | MP4 URL |
| `poster` | Poster image | `text` | `""` | Unsplash placeholder |
| `controls` | Controls | `radio` | `"on"` | `"on"` \| `"off"` |
| `autoPlay` | Auto-play | `radio` | `"off"` | `"on"` \| `"off"` |
| `loop` | Loop | `radio` | `"off"` | `"on"` \| `"off"` |
| `muted` | Muted | `radio` | `"off"` | `"on"` \| `"off"` |
| `borderRadius` | Border radius | `select` | `"md"` | Radius steps |
| `aspectRatio` | Aspect ratio | `radio` | `"16:9"` | `"auto"`, `"16:9"`, `"4:3"`, `"1:1"` |

#### YouTube

Embeds a YouTube video from any URL format.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `url` | YouTube URL | `text` | `""` | Accepts `youtube.com/watch?v=`, `youtu.be/`, `/embed/`, `/shorts/` |
| `aspectRatio` | Aspect ratio | `radio` | `"16:9"` | `"auto"`, `"16:9"`, `"4:3"`, `"1:1"` |
| `borderRadius` | Border radius | `select` | `"md"` | Radius steps |

#### Hero

Full-bleed hero banner with title, description, buttons, and optional background image.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `title` | Title | `text` | `"Hero title"` | — |
| `description` | Description | `richtext` | `""` | TipTap rich text |
| `buttons` | Buttons | `array` | `[]` | Array of `{ label, labelAr, href, variant }` |
| `align` | Alignment | `radio` | `"center"` | `"left"`, `"center"`, `"right"` |
| `padding` | Padding | `select` | `"80px"` | `spacingOptions` |
| `image.url` | Background image | `text` | `""` | URL |
| `image.mode` | Image mode | `radio` | `"none"` | `none`, `background`, `split` |
| `image.backgroundAttachment` | Attachment | `radio` | `"scroll"` | `scroll`, `fixed` |

#### Card

Generic content card.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `title` | Title | `text` | `""` | — |
| `description` | Description | `richtext` | `""` | — |
| `image` | Image | `object` | — | `{ url, alt }` |
| `variant` | Variant | `radio` | `"default"` | `"default"`, `"outlined"`, `"elevated"` |
| `colorMode` / `colorTheme` / `colorFixed` | Color | — | — | Shared color fields |

#### Badge

Small label/chip (e.g. discount, stock status).

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `label` | Label | `text` | `"Badge"` | Text content |
| `labelAr` | Label (Arabic) | `text` | `""` | — |
| `variant` | Variant | `radio` | `"discount"` | `"discount"`, `"inStock"`, `"outOfStock"`, `"custom"` |
| `colorMode` / `colorTheme` / `colorFixed` | Color | — | — | Shared color fields |
| `size` | Size | `radio` | `"sm"` | `"sm"`, `"md"`, `"lg"` |

#### Divider

Horizontal or vertical rule.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `orientation` | Orientation | `radio` | `"horizontal"` | `"horizontal"` \| `"vertical"` |
| `thickness` | Thickness | `select` | `"1px"` | `"1px"`, `"2px"`, `"3px"`, `"4px"` |
| `colorMode` / `colorTheme` / `colorFixed` | Color | — | — | Shared color fields |
| `width` | Width | `text` | `"100%"` | CSS value (horizontal only) |
| `height` | Height | `text` | `"100%"` | CSS value (vertical only) |

---

### 5.3 Commerce Blocks

#### ProductImage

Displays a product image.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `product` | Product | `external` | first product | Searchable product picker |
| `showBadges` | Show badges | `radio` | `"on"` | `"on"` \| `"off"` |
| `aspectRatio` | Aspect ratio | `radio` | `"square"` | `"auto"`, `"square"`, `"landscape"`, `"portrait"`, `"wide"` |
| `width` | Width | `text` | `"100%"` | — |
| `borderRadius` | Radius | `select` | `"md"` | Radius steps |
| `objectFit` | Object fit | `select` | `"cover"` | `cover`, `contain`, `fill`, `none` |

#### ProductCard

Individual product card with image, title, price, badges.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `product` | Product | `external` | first product | Searchable via `productExternalField` |
| `variant` | Layout | `radio` | `"vertical"` | `"vertical"`, `"horizontal"` |
| `colorScheme` | Color scheme | `radio` | `"light"` | `"light"` \| `"dark"` |
| `fontFamily` | Font | `select` | `"body"` | Font options |
| `fontWeight` | Font weight | `select` | `"500"` | Font weight steps |
| `lineHeight` | Line height | `select` | `"normal"` | Line height steps |
| `imageMode` | Image mode | `radio` | `"img"` | `"img"` \| `"background"` |
| `imageHeight` | Image height | `text` | `"200px"` | — |
| `imageBorderRadius` | Image radius | `select` | `"md"` | Radius steps |
| `imageObjectFit` | Object fit | `select` | `"cover"` | `cover`, `contain`, `fill` |
| `imageBackgroundSize` | BG size | `select` | `"cover"` | `cover`, `contain`, `auto` |
| `imageBackgroundPosition` | BG position | `select` | `"center"` | `center`, `top`, `bottom` |
| `imageBackgroundAttachment` | BG attachment | `radio` | `"scroll"` | `scroll`, `fixed` |
| `spacing` | Spacing | `select` | `"normal"` | `"compact"`, `"normal"`, `"relaxed"` |
| `showDescription` | Show description | `radio` | `"on"` | `"on"` \| `"off"` |
| `showCategories` | Show categories | `radio` | `"on"` | `"on"` \| `"off"` |
| `showBadge` | Show discount badge | `radio` | `"on"` | `"on"` \| `"off"` |
| `showStockBadge` | Show stock badge | `radio` | `"on"` | `"on"` \| `"off"` |
| `advanced` | Advanced | `object` | — | Sub-fields for fine-grained CSS: `backgroundColor`, `textColor`, `accentColor`, `priceColor`, `borderColor`, `titleFontSize`, `titleFontWeight`, `descriptionFontSize`, `descriptionLineClamp`, `priceFontSize`, `borderRadius`, `cardPadding`, `contentGap`, `imageWidth`, `borderWidth`, `boxShadow` |

#### ProductGrid

Grid of product cards.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `collection` | Collection filter | `select` | `"all"` | `"all"` or any `allCollections` value |
| `maxProducts` | Max products | `select` | `"6"` | 1–12 |
| `columns` | Columns | `radio` | `"3"` | 2, 3, 4 |
| `variant` | Card variant | `radio` | `"vertical"` | `"vertical"`, `"horizontal"` |
| `gap` | Gap | `select` | `24` | 4–32 in 4px steps |
| `colorScheme` | Color scheme | `radio` | `"light"` | `"light"` \| `"dark"` |

Inherits card display fields (fontFamily, fontWeight, spacing, showDescription, etc.)

#### ProductCarousel

Horizontal carousel/scrollable strip of product cards.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `collection` | Collection | `select` | `"all"` | — |
| `maxProducts` | Max products | `select` | `"8"` | 2–20 |
| `variant` | Card variant | `radio` | `"vertical"` | `"vertical"`, `"horizontal"` |
| `autoPlay` | Auto-play | `radio` | `"off"` | `"on"` \| `"off"` |
| `autoPlayIntervalMs` | Interval | `text` | `"3000"` | Milliseconds |

Inherits card display fields.

#### ProductDetails

Full product detail layout (title, image, price, description, add-to-cart, SKU, categories). Uses a hard-coded layout from demo data.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `product` | Product | `external` | first product | Searchable |
| `layout` | Layout | `radio` | `"standard"` | `"standard"`, `"stacked"` |
| `showBreadcrumb` | Show breadcrumb | `radio` | `"on"` | `"on"` \| `"off"` |
| `showSku` | Show SKU | `radio` | `"on"` | `"on"` \| `"off"` |
| `showCategories` | Show categories | `radio` | `"on"` | `"on"` \| `"off"` |
| `showQuantitySelector` | Quantity selector | `radio` | `"on"` | `"on"` \| `"off"` |
| `quantity` | Default quantity | `number` | `1` | 1–99 |

#### CartSection

Full shopping cart table with line items, quantity controls, remove buttons, and per-item totals. Uses mock cart data.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `showCouponInput` | Show coupon | `radio` | `"on"` | `"on"` \| `"off"` |
| `showRemoveButton` | Show remove | `radio` | `"on"` | `"on"` \| `"off"` |

#### CartSummary

Sidebar summary with subtotal, shipping, estimated tax, and total.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `showShippingEstimate` | Show shipping | `radio` | `"on"` | `"on"` \| `"off"` |
| `showTaxEstimate` | Show tax | `radio` | `"on"` | `"on"` \| `"off"` |

#### CheckoutForm

Checkout form with shipping address and payment method fields (demo/mock).

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `showBillingAddress` | Show billing | `radio` | `"off"` | `"on"` \| `"off"` |
| `showOrderNotes` | Show order notes | `radio` | `"on"` | `"on"` \| `"off"` |

#### CheckoutSummary

Order summary displayed alongside the checkout form.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `showShippingEstimate` | Show shipping | `radio` | `"on"` | `"on"` \| `"off"` |
| `showTaxEstimate` | Show tax | `radio` | `"on"` | `"on"` \| `"off"` |
| `showOrderNotes` | Show notes | `radio` | `"on"` | `"on"` \| `"off"` |

#### OrderList

Table of recent orders with status badges.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `maxOrders` | Max orders | `select` | `"5"` | 1–20 |
| `showStatus` | Show status | `radio` | `"on"` | `"on"` \| `"off"` |
| `showDate` | Show date | `radio` | `"on"` | `"on"` \| `"off"` |
| `showTotal` | Show total | `radio` | `"on"` | `"on"` \| `"off"` |
| `showThumbnail` | Show thumbnail | `radio` | `"on"` | `"on"` \| `"off"` |

#### OrderDetails

Detailed view of a single order.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `orderId` | Order ID | `select` | first order | From `sampleOrders` options |
| `showTimeline` | Show timeline | `radio` | `"on"` | `"on"` \| `"off"` |
| `showItems` | Show items | `radio` | `"on"` | `"on"` \| `"off"` |

---

### 5.4 Testimonial Blocks

#### TestimonialCard

Single testimonial with avatar, name, role, rating, text.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `testimonial` | Testimonial | `select` | first entry | From `sampleTestimonials` options |
| `showAvatar` | Show avatar | `radio` | `"on"` | `"on"` \| `"off"` |
| `showRating` | Show rating | `radio` | `"on"` | `"on"` \| `"off"` |
| `variant` | Variant | `radio` | `"default"` | `"default"`, `"outlined"`, `"elevated"` |

#### TestimonialGrid

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `columns` | Columns | `radio` | `"3"` | 1, 2, 3, 4 |
| `gap` | Gap | `select` | `24` | 4–32 in 4px steps |
| `maxItems` | Max items | `select` | `"6"` | 1–12 |
| `showAvatar` | Show avatar | `radio` | `"on"` | `"on"` \| `"off"` |
| `showRating` | Show rating | `radio` | `"on"` | `"on"` \| `"off"` |
| `cardVariant` | Card variant | `radio` | `"default"` | `"default"`, `"outlined"`, `"elevated"` |

---

### 5.5 Shell Blocks

#### SiteHeader

Site-wide header block (placed in root DropZone). Draws from root props for links, brand, colors. Renders logo, navigation links, drawer toggle button.

**No configurable fields in the block itself** — all props come from root config (`headerLinks`, `headerBrandTitle`, etc.).

#### SiteFooter

Site-wide footer with columns of links. Renders brand, tagline, link columns.

**No configurable fields in the block itself** — props come from root config (`footerColumns`, `footerTagline`, etc.). Columns are `FooterColumn[]` from `config/components/Footer`.

#### SiteDrawerShell

Side-panel drawer (left/right rail). Uses root config for all behavior.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |

#### Logo

Simple image logo block for use in headers, footers, etc.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `src` | Image URL | `text` | `""` | — |
| `alt` | Alt text | `text` | `"Logo"` | — |
| `width` | Width | `text` | `"120"` | Pixels |
| `height` | Height | `text` | `"36"` | Pixels |

---

### 5.6 Utility Blocks

#### Html

Raw HTML block.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `html` | HTML | `textarea` | `""` | Raw HTML string |

#### Countdown

Countdown timer to a target date.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `targetDate` | Target date | `text` | future date | ISO 8601 string |
| `title` | Title | `text` | `""` | Optional heading above timer |
| `titleAr` | Title (Arabic) | `text` | `""` | — |
| `size` | Size | `radio` | `"md"` | `"sm"`, `"md"`, `"lg"` |
| `showDays` / `showHours` / `showMinutes` / `showSeconds` | Units | `radio` | all `"on"` | `"on"` \| `"off"` |

#### CookieConsent

GDPR cookie consent banner.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `message` | Message | `text` | default | — |
| `messageAr` | Message (Arabic) | `text` | default | — |
| `acceptLabel` | Accept label | `text` | `"Accept"` | — |
| `acceptLabelAr` | Accept label (AR) | `text` | `"قبول"` | — |
| `declineLabel` | Decline label | `text` | `"Decline"` | — |
| `declineLabelAr` | Decline label (AR) | `text` | `"رفض"` | — |
| `position` | Position | `radio` | `"bottom"` | `"top"`, `"bottom"` |

#### SearchModal

Product search modal with live filtering.

| Field | Label | Type | Default | Options |
|---|---|---|---|---|
| `id` | ID | `text` | auto-generated | — |
| `placeholder` | Placeholder | `text` | `"Search products…"` | — |
| `placeholderAr` | Placeholder (AR) | `text` | `"بحث عن منتجات…"` | — |
| `maxResults` | Max results | `select` | `"8"` | 4–20 |
| `showPrice` | Show price | `radio` | `"on"` | `"on"` \| `"off"` |
| `showCategory` | Show category | `radio` | `"on"` | `"on"` \| `"off"` |

---

## 6. Shared Fields

### 6.1 Typography (config/content/typography-fields.ts)

Mode toggle: `"theme"` / `"fixed"` (radio).

| Field | Options | Description |
|---|---|---|
| Text size | `xs`, `sm`, `md`, `lg`, `xl`, `2xl` | Maps to `--theme-text-size-{step}` |
| Radius | `none`, `sm`, `md`, `lg`, `xl`, `full` | Maps to `--theme-radius-{step}` |
| Font weight | `normal`, `medium`, `semibold`, `bold` | Maps to `--theme-font-weight-{step}` |
| Line height | `tight`, `normal`, `relaxed` | Maps to `--theme-line-height-{step}` |

### 6.2 Color (config/content/color-fields.tsx)

Three-field combo on many content blocks:

| Field | Type | Options |
|---|---|---|
| `colorMode` | radio | `"theme"` / `"fixed"` |
| `colorTheme` | select | All 8 ColorKey values (primary, surface, success, warning, error, dark, text, neutral) |
| `colorFixed` | custom | Color picker + hex text input |

Resolver: `resolveContentColor(mode, theme, fixed) → CSS color string`.

### 6.3 Button Action (config/content/button-actions.ts)

| Action | Value | Description |
|---|---|---|
| Link | `"link"` | Navigate to a URL |
| Login | `"login"` | Trigger login flow |
| Logout | `"logout"` | Trigger logout flow |
| Add to cart | `"addToCart"` | Add item to cart |
| Add to wishlist | `"addToWishlist"` | Add item to wishlist |

### 6.4 Link Object

Used by Button and Link blocks:

| Sub-field | Type | Options |
|---|---|---|
| `kind` | radio | `"page"` / `"url"` |
| `pageId` | text | Path when kind=page |
| `url` | text | URL when kind=url |
| `newWindow` | radio | `"on"` / `"off"` |

### 6.5 YouTube URL Normalizer (config/content/youtube.ts)

`toYouTubeEmbedUrl(input)` normalizes:
- `youtube.com/watch?v=ID` → `youtube.com/embed/ID`
- `youtu.be/ID` → `youtube.com/embed/ID`
- `youtube.com/shorts/ID` → `youtube.com/embed/ID`
- Already `/embed/` URLs pass through

---

## 7. Data Fixtures

File: `config/data/`

### 7.1 Products (`products.ts`)

Type `Product`:

| Field | Type | Description |
|---|---|---|
| `id` | `string` | e.g. `"prod-001"` |
| `title` | `string` | Product name |
| `image` | `string` | Unsplash URL |
| `description` | `string` | Short description |
| `price` | `number` | In USD (display via `formatPrice()`) |
| `inStock` | `boolean` | — |
| `categories` | `string[]` | e.g. `["Footwear", "Men", "Casual"]` |
| `collections` | `string[]` | e.g. `["Summer 2025", "Essentials"]` |
| `discount` | `number?` | Percentage 0–100 (undefined = none) |

**14 products** with IDs `prod-001` through `prod-014`. Two out-of-stock (`prod-004`, `prod-014`). Most have discounts.

Helpers: `formatPrice(price)`, `discountedPrice(price, discount)`, `productOptions` (label/value for select fields), `allCollections` (unique sorted collection names), `productExternalField` (reusable external field definition for product pickers).

### 7.2 Cart (`cart.ts`)

Type `MockCartLine`: `{ lineId, productId, quantity }`.

**Mock cart** has 5 items (product IDs: prod-001×2, prod-003×1, prod-007×3, prod-011×1, prod-002×1).

Helpers: `resolveCartLine(line) → ResolvedCartLine`, `resolveMockCartLines()`, `cloneMockCartItems()`, `mockCartSubtotal(lines)`.

### 7.3 Checkout (`checkout.ts`)

Type `MockShippingAddress`: `{ fullName, line1, line2, city, region, postalCode, country }`.

Type `MockPaymentMethod`: `{ brand, last4, expiry }`.

**Constants:** `CHECKOUT_DEMO_SHIPPING = 9.99`, `CHECKOUT_DEMO_TAX_RATE = 0.0825`.

Helpers: `getCheckoutOrderLines()`, `getCheckoutSubtotal(lines)`, `getCheckoutEstimatedTax(subtotal)`, `getCheckoutTotal(subtotal, shipping, tax)`.

### 7.4 Orders (`orders.ts`)

Type `OrderStatus`: `"pending" | "confirmed" | "shipped" | "delivered" | "cancelled" | "returned"`.

Type `Order`: `{ id, orderNumber, date, status, total, itemCount, thumbnail? }`.

**4 sample orders** (`ord-1001` through `ord-1004`) in various statuses.

### 7.5 Testimonials (`testimonials.ts`)

Type `Testimonial`: `{ id, name, nameAr?, role?, roleAr?, avatar?, rating, text, textAr? }`.

**3 testimonials** (`t-1`, `t-2`, `t-3`) from bilingual customers (Arabic + English fields).

---

## 8. JSON Structure Examples

### 8.1 Overall Page Structure (empty, main keys only)

```json
{
  "root": {
    "props": {}
  },
  "content": [],
  "zones": {}
}
```

**Breakdown:**
- `root.props` — system settings (locale, fonts, colors, header, footer, drawer, badges, breakpoints, scales)
- `content` — array of top-level blocks rendered in the main DropZone (SiteHeader, Section, SiteFooter)
- `zones` — named zones for shell areas (e.g. `"shell-left"`, `"shell-right"` accepting SiteDrawerShell)

### 8.2 Section with Nested Children (Grid, Heading, Text, Button)

This is the most common pattern — a Section wrapping a Grid, which itself wraps ProductCards:

```json
{
  "root": {
    "props": {
      "title": "متجر Ertqaa",
      "direction": "rtl",
      "language": "ar",
      "currency": "SYP",
      "bodyFont": "dm-sans",
      "fontOption1": "space-grotesk",
      "fontOption2": "fraunces",
      "primary": "#0b78c5",
      "surface": "#f6f8fc",
      "text": "#14243f",
      "headerVisible": true,
      "footerVisible": true,
      "badgeShape": "rounded",
      "badgeStyle": "solid",
      "breakpointMobileMax": 767,
      "breakpointTabletMax": 1023
    }
  },
  "content": [
    {
      "type": "SiteHeader",
      "props": {
        "id": "SiteHeader-1"
      }
    },
    {
      "type": "Section",
      "props": {
        "id": "Section-products",
        "paddingTop": "80px",
        "paddingBottom": "80px",
        "paddingHorizontal": "24px",
        "backgroundColor": "#ffffff",
        "theme": "light",
        "maxWidth": "1280px",
        "content": [
          {
            "type": "Heading",
            "props": {
              "id": "Heading-title",
              "text": "Our Products",
              "level": "2",
              "align": "center",
              "size": "xl",
              "fontFamily": "option1",
              "colorMode": "theme",
              "colorTheme": "text",
              "colorFixed": "#0f172a",
              "layout": {
                "padding": "0px"
              }
            }
          },
          {
            "type": "Space",
            "props": {
              "id": "Space-spacer",
              "size": "40px",
              "direction": "vertical"
            }
          },
          {
            "type": "Grid",
            "props": {
              "id": "Grid-product-grid",
              "numColumns": 3,
              "gap": 24,
              "items": [
                {
                  "type": "ProductCard",
                  "props": {
                    "id": "ProductCard-1",
                    "product": {
                      "id": "prod-001",
                      "title": "Classic White Sneakers",
                      "image": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&auto=format&fit=crop&q=80",
                      "description": "Clean, minimalist leather sneakers built for everyday comfort.",
                      "price": 89.99,
                      "inStock": true,
                      "categories": ["Footwear", "Men", "Casual"],
                      "collections": ["Summer 2025", "Essentials"],
                      "discount": 10
                    },
                    "variant": "vertical",
                    "colorScheme": "light",
                    "fontFamily": "body",
                    "fontWeight": "500",
                    "lineHeight": "normal",
                    "imageMode": "img",
                    "imageHeight": "200px",
                    "imageBorderRadius": "md",
                    "imageObjectFit": "cover",
                    "spacing": "normal",
                    "showDescription": true,
                    "showCategories": true,
                    "showBadge": true,
                    "showStockBadge": true,
                    "layout": {
                      "grow": true,
                      "spanCol": 1,
                      "spanRow": 1,
                      "padding": "0px"
                    },
                    "advanced": {}
                  }
                },
                {
                  "type": "ProductCard",
                  "props": {
                    "id": "ProductCard-2",
                    "product": {
                      "id": "prod-002",
                      "title": "Wireless Noise-Cancelling Headphones",
                      "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&auto=format&fit=crop&q=80",
                      "description": "40-hour battery life, adaptive noise cancellation, and premium sound.",
                      "price": 249.0,
                      "inStock": true,
                      "categories": ["Electronics", "Audio"],
                      "collections": ["Tech Picks", "New Arrivals"]
                    },
                    "variant": "vertical",
                    "colorScheme": "light",
                    "imageHeight": "200px",
                    "layout": {
                      "grow": true,
                      "spanCol": 1,
                      "spanRow": 1,
                      "padding": "0px"
                    }
                  }
                },
                {
                  "type": "ProductCard",
                  "props": {
                    "id": "ProductCard-3",
                    "product": {
                      "id": "prod-003",
                      "title": "Linen Tote Bag",
                      "image": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&auto=format&fit=crop&q=80",
                      "description": "Eco-friendly natural linen tote with a large main compartment.",
                      "price": 34.5,
                      "inStock": true,
                      "categories": ["Accessories", "Women", "Bags"],
                      "collections": ["Eco Picks", "Summer 2025"],
                      "discount": 20
                    },
                    "variant": "vertical",
                    "colorScheme": "light",
                    "layout": {
                      "grow": true,
                      "spanCol": 1,
                      "spanRow": 1,
                      "padding": "0px"
                    }
                  }
                }
              ]
            }
          },
          {
            "type": "Space",
            "props": {
              "id": "Space-cta-gap",
              "size": "40px",
              "direction": "vertical"
            }
          },
          {
            "type": "Flex",
            "props": {
              "id": "Flex-cta-row",
              "direction": "row",
              "justifyContent": "center",
              "alignItems": "center",
              "wrap": "nowrap",
              "gap": 16,
              "items": [
                {
                  "type": "Button",
                  "props": {
                    "id": "Button-shop-all",
                    "label": "Shop All",
                    "labelAr": "تسوق الكل",
                    "buttonAction": "link",
                    "href": "/products/example-product",
                    "link": {
                      "kind": "page",
                      "pageId": "/products/example-product",
                      "url": "",
                      "newWindow": false
                    },
                    "variant": "primary",
                    "size": "md",
                    "fullWidth": "off",
                    "fontFamily": "body",
                    "colorMode": "theme",
                    "colorTheme": "primary",
                    "colorFixed": "#0f172a"
                  }
                }
              ]
            }
          }
        ]
      }
    },
    {
      "type": "SiteFooter",
      "props": {
        "id": "SiteFooter-1"
      }
    }
  ],
  "zones": {
    "shell-left": [],
    "shell-right": []
  }
}
```

### 8.3 Nested Blocks Inside Group (image + text side by side)

Group uses `content` (inline Slot, not array `items`). This example shows a row with ProductImage and a text column:

```json
{
  "type": "Section",
  "props": {
    "id": "Section-about",
    "paddingTop": "96px",
    "paddingBottom": "96px",
    "paddingHorizontal": "24px",
    "maxWidth": "1280px",
    "backgroundColor": "#ffffff",
    "theme": "light",
    "content": [
      {
        "type": "Group",
        "props": {
          "id": "Group-about-row",
          "direction": "row",
          "gap": 56,
          "alignItems": "center",
          "justifyContent": "flex-start",
          "wrap": "wrap",
          "layout": {
            "padding": "0px"
          },
          "content": [
            {
              "type": "ProductImage",
              "props": {
                "id": "ProductImage-about",
                "product": {
                  "id": "prod-005",
                  "title": "Merino Wool Crew Sweater",
                  "image": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&auto=format&fit=crop&q=80",
                  "description": "Lightweight, breathable 100% merino wool sweater.",
                  "price": 129.0,
                  "inStock": true,
                  "categories": ["Clothing", "Men", "Women"],
                  "collections": ["Autumn 2025", "Essentials"],
                  "discount": 15
                },
                "showBadges": false,
                "aspectRatio": "landscape",
                "width": "400px",
                "borderRadius": "lg",
                "objectFit": "cover",
                "layout": {
                  "grow": false,
                  "spanCol": 1,
                  "spanRow": 1,
                  "padding": "0px"
                }
              }
            },
            {
              "type": "Group",
              "props": {
                "id": "Group-about-text",
                "direction": "column",
                "gap": 20,
                "alignItems": "flex-start",
                "justifyContent": "center",
                "wrap": "nowrap",
                "layout": {
                  "grow": true,
                  "spanCol": 1,
                  "spanRow": 1,
                  "padding": "0px"
                },
                "content": [
                  {
                    "type": "Heading",
                    "props": {
                      "id": "Heading-about-title",
                      "text": "Our Story",
                      "level": "2",
                      "align": "left",
                      "size": "xl",
                      "fontFamily": "option1",
                      "colorMode": "theme",
                      "colorTheme": "text",
                      "colorFixed": "#0f172a",
                      "layout": {
                        "padding": "0px"
                      }
                    }
                  },
                  {
                    "type": "Text",
                    "props": {
                      "id": "Text-about-desc",
                      "text": "We believe in quality craftsmanship and sustainable practices. Every piece in our collection is thoughtfully sourced and designed to last.",
                      "align": "left",
                      "size": "m",
                      "color": "default",
                      "fontFamily": "body",
                      "layout": {
                        "padding": "0px"
                      }
                    }
                  },
                  {
                    "type": "Button",
                    "props": {
                      "id": "Button-about-cta",
                      "label": "Learn More",
                      "labelAr": "اعرف المزيد",
                      "buttonAction": "link",
                      "href": "/products/example-product",
                      "variant": "secondary",
                      "size": "md",
                      "fullWidth": "off",
                      "fontFamily": "body",
                      "colorMode": "theme",
                      "colorTheme": "primary",
                      "colorFixed": "#0f172a"
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    ]
  }
}
```

### 8.4 Hero Block (full-bleed with background image)

```json
{
  "type": "Hero",
  "props": {
    "id": "Hero-main",
    "title": "Summer Collection 2026",
    "description": "<p>Discover lightweight styles crafted for warm days and warm nights.</p>",
    "buttons": [
      {
        "label": "Shop Now",
        "labelAr": "تسوق الآن",
        "href": "/products/example-product",
        "variant": "primary"
      },
      {
        "label": "Learn More",
        "href": "/themes",
        "variant": "secondary"
      }
    ],
    "align": "center",
    "padding": "140px",
    "image": {
      "url": "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=2000&auto=format&fit=crop&q=80",
      "mode": "background",
      "backgroundAttachment": "scroll",
      "content": []
    }
  }
}
```

### 8.5 Grid Block (standalone — items array)

```json
{
  "type": "Grid",
  "props": {
    "id": "Grid-featured",
    "numColumns": 2,
    "gap": 24,
    "items": [
      {
        "type": "Card",
        "props": {
          "id": "Card-1",
          "title": "Free Shipping",
          "description": "<p>On orders over 200 SAR</p>",
          "variant": "elevated",
          "colorMode": "theme",
          "colorTheme": "primary",
          "colorFixed": "#0f172a",
          "layout": {
            "spanCol": 1,
            "spanRow": 1,
            "grow": true,
            "padding": "0px"
          }
        }
      },
      {
        "type": "Card",
        "props": {
          "id": "Card-2",
          "title": "Easy Returns",
          "description": "<p>30-day return policy, no questions asked</p>",
          "variant": "elevated",
          "layout": {
            "spanCol": 1,
            "spanRow": 1,
            "grow": true,
            "padding": "0px"
          }
        }
      }
    ]
  }
}
```

### 8.6 Flex Block (standalone — items array)

```json
{
  "type": "Flex",
  "props": {
    "id": "Flex-icon-row",
    "direction": "row",
    "justifyContent": "center",
    "alignItems": "center",
    "wrap": "wrap",
    "gap": 24,
    "items": [
      {
        "type": "Icon",
        "props": {
          "id": "Icon-star",
          "name": "Star",
          "size": "32",
          "colorMode": "theme",
          "colorTheme": "primary",
          "colorFixed": "#0f172a",
          "strokeWidth": "2",
          "layout": {
            "padding": "0px"
          }
        }
      },
      {
        "type": "Icon",
        "props": {
          "id": "Icon-heart",
          "name": "Heart",
          "size": "32",
          "colorMode": "theme",
          "colorTheme": "error",
          "colorFixed": "#c24133",
          "strokeWidth": "2",
          "layout": {
            "padding": "0px"
          }
        }
      }
    ]
  }
}
```

### 8.7 Layout Block with Full Float/Custom Positioning

```json
{
  "type": "Badge",
  "props": {
    "id": "Badge-floating-discount",
    "label": "-20%",
    "labelAr": "-٢٠٪",
    "variant": "discount",
    "size": "md",
    "colorMode": "theme",
    "colorTheme": "error",
    "colorFixed": "#c24133",
    "layout": {
      "positionMode": "float",
      "floatUseFixedPosition": false,
      "floatPlacementMode": "preset",
      "floatPreset": "top-right",
      "marginTop": "8px",
      "marginRight": "8px",
      "borderWidth": "0px",
      "borderStyle": "none",
      "shadowMode": "preset",
      "shadowPreset": "md",
      "hideOnMobile": false,
      "hideOnTablet": false,
      "hideOnDesktop": false
    }
  }
}
```

### 8.8 Countdown Block

```json
{
  "type": "Countdown",
  "props": {
    "id": "Countdown-sale",
    "targetDate": "2026-07-15T23:59:59Z",
    "title": "Sale Ends In",
    "titleAr": "ينتهي التخفيض بعد",
    "size": "md",
    "showDays": "on",
    "showHours": "on",
    "showMinutes": "on",
    "showSeconds": "on"
  }
}
```

### 8.9 YouTube Block

```json
{
  "type": "YouTube",
  "props": {
    "id": "YouTube-product-video",
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "aspectRatio": "16:9",
    "borderRadius": "lg"
  }
}
```

### 8.10 Video Block

```json
{
  "type": "Video",
  "props": {
    "id": "Video-bg",
    "src": "https://example.com/video.mp4",
    "poster": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200&auto=format&fit=crop&q=80",
    "controls": "on",
    "autoPlay": "on",
    "loop": "on",
    "muted": "on",
    "borderRadius": "md",
    "aspectRatio": "16:9"
  }
}
```

### 8.11 Image Block

```json
{
  "type": "Image",
  "props": {
    "id": "Image-banner",
    "src": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200&auto=format&fit=crop&q=80",
    "alt": "Red sneakers on gradient background",
    "aspectRatio": "landscape",
    "borderRadius": "lg",
    "shadow": "md",
    "objectFit": "cover",
    "width": "100%",
    "height": "400px"
  }
}
```

### 8.12 Link Block

```json
{
  "type": "Link",
  "props": {
    "id": "Link-footer-about",
    "label": "About Us",
    "labelAr": "من نحن",
    "href": "/about",
    "link": {
      "kind": "page",
      "pageId": "/about",
      "url": "",
      "newWindow": false
    },
    "variant": "muted"
  }
}
```

### 8.13 Divider Block

```json
{
  "type": "Divider",
  "props": {
    "id": "Divider-section-break",
    "orientation": "horizontal",
    "thickness": "1px",
    "colorMode": "theme",
    "colorTheme": "neutral",
    "colorFixed": "#cbd5e1",
    "width": "100%",
    "height": "1px"
  }
}
```

### 8.14 Logo Block

```json
{
  "type": "Logo",
  "props": {
    "id": "Logo-brand",
    "src": "https://example.com/logo.png",
    "alt": "Ertqaa",
    "width": "120",
    "height": "36"
  }
}
```

### 8.15 HTML Block

```json
{
  "type": "Html",
  "props": {
    "id": "Html-custom-code",
    "html": "<div style=\"padding: 20px; background: #f0f0f0;\"><p>Custom HTML content</p></div>"
  }
}
```

### 8.16 CookieConsent Block

```json
{
  "type": "CookieConsent",
  "props": {
    "id": "CookieConsent-banner",
    "message": "We use cookies to improve your experience.",
    "messageAr": "نستخدم ملفات تعريف الارتباط لتحسين تجربتك.",
    "acceptLabel": "Accept",
    "acceptLabelAr": "قبول",
    "declineLabel": "Decline",
    "declineLabelAr": "رفض",
    "position": "bottom"
  }
}
```

### 8.17 SearchModal Block

```json
{
  "type": "SearchModal",
  "props": {
    "id": "SearchModal-header",
    "placeholder": "Search products…",
    "placeholderAr": "بحث عن منتجات…",
    "maxResults": "8",
    "showPrice": "on",
    "showCategory": "on"
  }
}
```

### 8.18 TestimonialCard Block

```json
{
  "type": "TestimonialCard",
  "props": {
    "id": "TestimonialCard-1",
    "testimonial": {
      "id": "t-1",
      "name": "Layla Haddad",
      "nameAr": "ليلى حداد",
      "role": "Café owner, Damascus",
      "roleAr": "صاحبة مقهى، دمشق",
      "avatar": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&auto=format&fit=crop&q=80",
      "rating": 5,
      "text": "Setting up our online store took less than an hour.",
      "textAr": "إنشاء متجرنا الإلكتروني استغرق أقل من ساعة."
    },
    "showAvatar": "on",
    "showRating": "on",
    "variant": "default"
  }
}
```

### 8.19 TestimonialGrid Block

```json
{
  "type": "TestimonialGrid",
  "props": {
    "id": "TestimonialGrid-section",
    "columns": "3",
    "gap": 24,
    "maxItems": "6",
    "showAvatar": "on",
    "showRating": "on",
    "cardVariant": "default"
  }
}
```

### 8.20 ProductDetails Block

```json
{
  "type": "ProductDetails",
  "props": {
    "id": "ProductDetails-main",
    "product": {
      "id": "prod-001",
      "title": "Classic White Sneakers",
      "image": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&auto=format&fit=crop&q=80",
      "description": "Clean, minimalist leather sneakers built for everyday comfort.",
      "price": 89.99,
      "inStock": true,
      "categories": ["Footwear", "Men", "Casual"],
      "collections": ["Summer 2025", "Essentials"],
      "discount": 10
    },
    "layout": "standard",
    "showBreadcrumb": "on",
    "showSku": "on",
    "showCategories": "on",
    "showQuantitySelector": "on",
    "quantity": 1
  }
}
```

### 8.21 ProductCarousel Block

```json
{
  "type": "ProductCarousel",
  "props": {
    "id": "ProductCarousel-featured",
    "collection": "all",
    "maxProducts": "8",
    "variant": "vertical",
    "autoPlay": "on",
    "autoPlayIntervalMs": "3000"
  }
}
```

### 8.22 ProductGrid Block

```json
{
  "type": "ProductGrid",
  "props": {
    "id": "ProductGrid-collection",
    "collection": "Summer 2025",
    "maxProducts": "6",
    "columns": "3",
    "variant": "vertical",
    "gap": 24,
    "colorScheme": "light",
    "fontFamily": "body",
    "fontWeight": "500",
    "spacing": "normal",
    "showDescription": "on",
    "showBadge": "on",
    "showStockBadge": "on",
    "imageMode": "img",
    "imageHeight": "200px"
  }
}
```

### 8.23 CartSection Block

```json
{
  "type": "CartSection",
  "props": {
    "id": "CartSection-main",
    "showCouponInput": "on",
    "showRemoveButton": "on"
  }
}
```

### 8.24 CartSummary Block

```json
{
  "type": "CartSummary",
  "props": {
    "id": "CartSummary-sidebar",
    "showShippingEstimate": "on",
    "showTaxEstimate": "on"
  }
}
```

### 8.25 CheckoutForm Block

```json
{
  "type": "CheckoutForm",
  "props": {
    "id": "CheckoutForm-main",
    "showBillingAddress": "off",
    "showOrderNotes": "on"
  }
}
```

### 8.26 CheckoutSummary Block

```json
{
  "type": "CheckoutSummary",
  "props": {
    "id": "CheckoutSummary-sidebar",
    "showShippingEstimate": "on",
    "showTaxEstimate": "on",
    "showOrderNotes": "on"
  }
}
```

### 8.27 OrderList Block

```json
{
  "type": "OrderList",
  "props": {
    "id": "OrderList-account",
    "maxOrders": "5",
    "showStatus": "on",
    "showDate": "on",
    "showTotal": "on",
    "showThumbnail": "on"
  }
}
```

### 8.28 OrderDetails Block

```json
{
  "type": "OrderDetails",
  "props": {
    "id": "OrderDetails-view",
    "orderId": "ord-1001",
    "showTimeline": "on",
    "showItems": "on"
  }
}
```

### 8.29 SiteDrawerShell Block (in shell zones)

```json
{
  "type": "SiteDrawerShell",
  "props": {
    "id": "SiteDrawerShell-left"
  }
}
```
(Placed in `zones. shell-left` or `zones. shell-right`)

### 8.30 Page with Zones (shell + content)

Full page JSON showing zones alongside content:

```json
{
  "root": {
    "props": {
      "title": "Home",
      "direction": "rtl",
      "language": "ar",
      "bodyFont": "dm-sans",
      "fontOption1": "space-grotesk",
      "fontOption2": "fraunces",
      "primary": "#0b78c5",
      "surface": "#f6f8fc",
      "text": "#14243f",
      "headerVisible": true,
      "footerVisible": true,
      "drawerEnabled": true,
      "drawerSide": "left",
      "drawerWidthPx": 320,
      "drawerAnimation": "slide",
      "headerShowDrawerButton": true
    }
  },
  "content": [
    {
      "type": "SiteHeader",
      "props": { "id": "SiteHeader-1" }
    },
    {
      "type": "Section",
      "props": {
        "id": "Section-hero",
        "paddingTop": "0px",
        "paddingBottom": "0px",
        "paddingHorizontal": "0px",
        "maxWidth": "100%",
        "backgroundColor": "transparent",
        "theme": "dark",
        "content": [
          {
            "type": "Hero",
            "props": {
              "id": "Hero-main",
              "title": "Welcome to Ertqaa",
              "description": "<p>Your destination for quality products</p>",
              "align": "center",
              "padding": "120px",
              "image": {
                "url": "https://images.unsplash.com/photo-1556761175-b413da4baf72?w=2000&auto=format&fit=crop&q=80",
                "mode": "background",
                "backgroundAttachment": "scroll",
                "content": []
              },
              "buttons": [
                { "label": "Shop Now", "variant": "primary", "href": "/products/example-product" }
              ]
            }
          }
        ]
      }
    },
    {
      "type": "SiteFooter",
      "props": { "id": "SiteFooter-1" }
    }
  ],
  "zones": {
    "shell-left": [
      {
        "type": "SiteDrawerShell",
        "props": { "id": "SiteDrawerShell-left" }
      }
    ],
    "shell-right": []
  }
}
```