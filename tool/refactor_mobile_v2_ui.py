#!/usr/bin/env python3
"""One-shot JSON UI refactor for mobile_production_v2.json."""

import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "assets" / "config" / "mobile_production_v2.json"

# Theme-aligned hex
BG = "#F1F5F9"
SURFACE = "#F8FAFC"
PRIMARY = "#1D4ED8"
TEXT = "#0F172A"
MUTED = "#475569"
WHITE = "#FFFFFF"
BORDER = "#E2E8F0"
RADIUS_MD = 10
RADIUS_LG = 14
PAD_PAGE = {"left": 16, "right": 16}
PRODUCT_FALLBACK = "https://picsum.photos/seed/sooq-product-fallback/400/400"
CATEGORY_FALLBACK = "https://picsum.photos/seed/sooq-category-fallback/400/400"


def app_bar(page_id: str, title: str, bg: str = WHITE) -> dict:
    return {
        "id": f"{page_id}-appbar",
        "type": "appBar",
        "props": {"title": title},
        "style": {"background": bg},
    }


def section_header(
    hid: str,
    title: str,
    action_label: str = "عرض الكل",
    route: str | None = None,
    navigation_type: str | None = "push",
) -> dict:
    children = [
        {
            "id": f"{hid}-title",
            "type": "text",
            "props": {
                "value": title,
                "fontSize": 20,
                "fontWeight": "bold",
                "textAlign": "right",
                "color": TEXT,
            },
        }
    ]
    if route:
        btn = {
            "id": f"{hid}-action",
            "type": "button",
            "props": {"label": action_label, "variant": "text", "textColor": PRIMARY},
            "tap": {"type": "navigate", "route": route},
        }
        if navigation_type:
            btn["tap"]["navigation_type"] = navigation_type
        children.append(btn)
    return {
        "id": hid,
        "type": "container",
        "style": {"padding": {**PAD_PAGE, "top": 12, "bottom": 8}},
        "child": {
            "id": f"{hid}-row",
            "type": "row",
            "props": {"mainAxis": "spaceBetween", "crossAxis": "center"},
            "children": children,
        },
    }


def product_tile_item(item_id: str) -> dict:
    return {
        "id": item_id,
        "type": "card",
        "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
        "child": {
            "id": f"{item_id}-content",
            "type": "column",
            "props": {"crossAxis": "stretch", "gap": 0},
            "children": [
                {
                    "id": f"{item_id}-image",
                    "type": "image",
                    "props": {
                        "source": "network",
                        "urlPath": "item.image",
                        "url": PRODUCT_FALLBACK,
                        "aspectRatio": 1,
                        "fit": "cover",
                    },
                },
                {
                    "id": f"{item_id}-body",
                    "type": "container",
                    "style": {"padding": {"left": 8, "right": 8, "top": 6, "bottom": 8}},
                    "child": {
                        "id": f"{item_id}-col",
                        "type": "column",
                        "props": {"crossAxis": "start", "gap": 2},
                        "children": [
                            {
                                "id": f"{item_id}-name",
                                "type": "text",
                                "props": {
                                    "valuePath": "item.name",
                                    "value": "",
                                    "fontSize": 14,
                                    "fontWeight": "semibold",
                                    "textAlign": "right",
                                    "color": TEXT,
                                    "maxLines": 2,
                                    "overflow": "ellipsis",
                                },
                            },
                            {
                                "id": f"{item_id}-price",
                                "type": "text",
                                "props": {
                                    "valuePath": "item.price",
                                    "value": "--",
                                    "fontSize": 15,
                                    "fontWeight": "bold",
                                    "textAlign": "right",
                                    "color": PRIMARY,
                                },
                            },
                        ],
                    },
                },
            ],
        },
        "tap": {
            "type": "navigate",
            "route": "/product/details/:productId",
            "navigation_type": "push",
        },
    }


def category_tile_item(item_id: str) -> dict:
    tile = copy.deepcopy(product_tile_item(item_id))
    tile["child"]["children"][0]["props"]["urlPath"] = "item.imageUrl"
    tile["child"]["children"][0]["props"]["url"] = CATEGORY_FALLBACK
    tile["tap"] = {
        "type": "navigate",
        "route": "/categories/:categorySlug/products",
        "navigation_type": "push",
    }
    return tile


def product_grid(
    gid: str,
    request_key: str,
    request_url: str,
    source: str,
    page: int = 0,
    size: int = 20,
    aspect: float = 0.68,
    q_field: str | None = None,
    collection_id: str | None = None,
    empty_message: str = "لا توجد منتجات",
    error_message: str = "تعذر تحميل المنتجات",
) -> dict:
    data = {
        "source": "collection",
        "id": collection_id or gid,
        "requestKey": request_key,
        "requestUrl": request_url,
    }
    if q_field:
        data["qField"] = q_field
    if page is not None:
        data["page"] = page
        data["size"] = size
    return {
        "id": gid,
        "type": "gridView",
        "props": {
            "crossAxisCount": 2,
            "mainAxisSpacing": 10,
            "crossAxisSpacing": 10,
            "childAspectRatio": aspect,
            "enableInnerScroll": False,
            "data": data,
            "emptyMessage": empty_message,
            "errorMessage": error_message,
        },
        "style": {"padding": {**PAD_PAGE, "bottom": 16}},
        "itemBuilder": {
            "type": "repeat",
            "source": source,
            "item": product_tile_item(f"{gid}-item"),
        },
    }


def category_grid(
    gid: str,
    request_key: str,
    request_url: str,
    source: str,
    aspect: float = 0.75,
) -> dict:
    tile = category_tile_item(f"{gid}-item")
    # Category tiles: name only (no price row).
    body_col = tile["child"]["children"][1]["child"]["child"]
    body_col["children"] = [body_col["children"][0]]
    return {
        "id": gid,
        "type": "gridView",
        "props": {
            "crossAxisCount": 2,
            "mainAxisSpacing": 10,
            "crossAxisSpacing": 10,
            "childAspectRatio": aspect,
            "enableInnerScroll": False,
            "data": {
                "source": "collection",
                "id": gid,
                "requestKey": request_key,
                "requestUrl": request_url,
            },
            "emptyMessage": "لا توجد أقسام",
            "errorMessage": "تعذر تحميل الأقسام",
        },
        "style": {"padding": {**PAD_PAGE, "bottom": 12}},
        "itemBuilder": {
            "type": "repeat",
            "source": source,
            "item": tile,
        },
    }


def search_entry_container(cid: str = "home-search-entry") -> dict:
    return {
        "id": cid,
        "type": "container",
        "style": {
            "margin": {**PAD_PAGE, "top": 12, "bottom": 12},
            "padding": 12,
            "background": SURFACE,
            "borderRadius": RADIUS_MD,
            "border": {"width": 1, "color": BORDER},
        },
        "tap": {"type": "navigate", "route": "/search"},
        "child": {
            "id": f"{cid}-row",
            "type": "row",
            "props": {"crossAxis": "center", "mainAxis": "spaceBetween", "gap": 8},
            "children": [
                {
                    "id": f"{cid}-icon",
                    "type": "icon",
                    "props": {"name": "search", "size": 22, "color": MUTED},
                },
                {
                    "id": f"{cid}-text",
                    "type": "text",
                    "props": {
                        "value": "ابحث عن منتجاتك المفضلة…",
                        "fontSize": 14,
                        "textAlign": "right",
                        "color": MUTED,
                    },
                },
            ],
        },
    }


def hero_banner() -> dict:
    return {
        "id": "home-hero-section",
        "type": "container",
        "style": {
            "margin": {**PAD_PAGE, "bottom": 12},
            "padding": 20,
            "background": TEXT,
            "borderRadius": RADIUS_LG,
            "shadow": "lg",
        },
        "child": {
            "id": "home-hero-column",
            "type": "column",
            "props": {"crossAxis": "start", "gap": 10},
            "children": [
                {
                    "id": "home-hero-kicker",
                    "type": "container",
                    "style": {
                        "padding": {"left": 8, "right": 8, "top": 4, "bottom": 4},
                        "background": PRIMARY,
                        "borderRadius": 8,
                    },
                    "child": {
                        "id": "home-hero-kicker-text",
                        "type": "text",
                        "props": {
                            "value": "تخفيضات الصيف",
                            "fontSize": 12,
                            "fontWeight": "medium",
                            "textAlign": "right",
                            "color": WHITE,
                        },
                    },
                },
                {
                    "id": "home-hero-title",
                    "type": "text",
                    "props": {
                        "value": "خصومات حتى 60%",
                        "fontSize": 24,
                        "fontWeight": "bold",
                        "textAlign": "right",
                        "color": WHITE,
                    },
                },
                {
                    "id": "home-hero-description",
                    "type": "richtext",
                    "props": {
                        "value": "<p>أفضل العروض على الإلكترونيات والأزياء والمنزل.</p>",
                        "color": BORDER,
                    },
                },
                {
                    "id": "home-hero-cta",
                    "type": "button",
                    "props": {"label": "تسوق الآن", "variant": "filled", "fullWidth": True},
                    "tap": {
                        "type": "navigate",
                        "route": "/products",
                        "navigation_type": "push",
                    },
                },
            ],
        },
    }


def page_home() -> list:
    return [
        search_entry_container(),
        hero_banner(),
        section_header(
            "home-categories-header",
            "الأقسام",
            route="/categories/browse",
            navigation_type="push",
        ),
        category_grid(
            "home-categories-grid",
            "home-categories",
            "/api/v1/public/categories",
            "dataContext.requests.home-categories.data",
        ),
        section_header(
            "home-featured-header",
            "منتجات مميزة",
            action_label="عرض كل المنتجات",
            route="/products",
            navigation_type="push",
        ),
        product_grid(
            "home-featured-grid",
            "home-featured-products",
            "/api/v1/public/products?page=0&size=6",
            "dataContext.requests.home-featured-products.data",
            page=0,
            size=6,
        ),
    ]


def page_categories_list() -> list:
    return [
        {
            "id": "categories-list",
            "type": "listView",
            "props": {
                "enableInnerScroll": False,
                "data": {
                    "source": "collection",
                    "id": "category-tree",
                    "requestKey": "category-tree",
                    "requestUrl": "/api/v1/public/categories",
                },
                "emptyMessage": "لا توجد أقسام",
                "errorMessage": "تعذر تحميل الأقسام",
            },
            "style": {"padding": 16},
            "itemBuilder": {
                "type": "repeat",
                "source": "dataContext.requests.category-tree.data",
                "item": {
                    "id": "cat-list-item",
                    "type": "card",
                    "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
                    "style": {"margin": {"bottom": 8}},
                    "child": {
                        "id": "cat-list-item-row-wrap",
                        "type": "container",
                        "style": {"padding": 12},
                        "child": {
                            "id": "cat-list-item-row",
                            "type": "row",
                            "props": {"mainAxis": "spaceBetween", "crossAxis": "center"},
                            "children": [
                                {
                                    "id": "cat-list-leading",
                                    "type": "row",
                                    "props": {"crossAxis": "center", "gap": 12},
                                    "children": [
                                        {
                                            "id": "cat-list-thumb",
                                            "type": "image",
                                            "props": {
                                                "source": "network",
                                                "urlPath": "item.imageUrl",
                                                "url": CATEGORY_FALLBACK,
                                                "width": 56,
                                                "height": 56,
                                                "fit": "cover",
                                            },
                                            "style": {"borderRadius": RADIUS_MD},
                                        },
                                        {
                                            "id": "cat-list-name",
                                            "type": "text",
                                            "props": {
                                                "valuePath": "item.name",
                                                "value": "",
                                                "fontSize": 15,
                                                "fontWeight": "semibold",
                                                "textAlign": "right",
                                                "color": TEXT,
                                            },
                                        },
                                    ],
                                },
                                {
                                    "id": "cat-list-chevron",
                                    "type": "icon",
                                    "props": {
                                        "name": "chevron_left",
                                        "size": 22,
                                        "color": MUTED,
                                    },
                                },
                            ],
                        },
                    },
                    "tap": {
                        "type": "navigate",
                        "route": "/categories/:categorySlug/products",
                        "navigation_type": "push",
                    },
                },
            },
        }
    ]


def page_products() -> list:
    return [
        {
            "id": "products-toolbar",
            "type": "container",
            "style": {"padding": {**PAD_PAGE, "top": 12, "bottom": 8}},
            "child": {
                "id": "products-toolbar-row",
                "type": "row",
                "props": {"mainAxis": "spaceBetween", "crossAxis": "center", "gap": 8},
                "children": [
                    {
                        "id": "products-count-hint",
                        "type": "text",
                        "props": {
                            "value": "تصفح كل المنتجات",
                            "fontSize": 14,
                            "textAlign": "right",
                            "color": MUTED,
                        },
                    },
                    {
                        "id": "products-filter-btn",
                        "type": "button",
                        "props": {"label": "تصفية", "variant": "outlined"},
                    },
                ],
            },
        },
        product_grid(
            "products-grid",
            "product-list",
            "/api/v1/public/products?page=0&size=20",
            "dataContext.requests.product-list.data",
        ),
    ]


def page_product_detail() -> list:
    return [
        {
            "id": "product-detail-request",
            "type": "container",
            "props": {
                "data": {
                    "requestKey": "product-detail",
                    "requestUrl": "/api/v1/public/products/:productId",
                    "include": "PRICING,IMAGES,VARIANTS,CATEGORIES,TAGS",
                }
            },
            "child": {
                "id": "product-detail-col",
                "type": "column",
                "props": {"crossAxis": "stretch", "gap": 0},
                "children": [
                    {
                        "id": "product-hero-image",
                        "type": "image",
                        "props": {
                            "source": "network",
                            "urlPath": "dataContext.requests.product-detail.data.primaryImageUrl",
                            "url": PRODUCT_FALLBACK,
                            "aspectRatio": 1,
                            "fit": "cover",
                        },
                        "style": {"padding": {**PAD_PAGE, "top": 12, "bottom": 8}},
                    },
                    {
                        "id": "product-gallery-strip",
                        "type": "listView",
                        "props": {"enableInnerScroll": True, "scrollDirection": "horizontal"},
                        "style": {"padding": {"left": 16, "bottom": 12}, "height": 72},
                        "itemBuilder": {
                            "type": "repeat",
                            "source": "dataContext.requests.product-detail.data.images",
                            "item": {
                                "id": "product-gallery-thumb",
                                "type": "container",
                                "style": {"margin": {"right": 8}},
                                "child": {
                                    "id": "product-gallery-thumb-image",
                                    "type": "image",
                                    "props": {
                                        "source": "network",
                                        "urlPath": "item.publicUrl",
                                        "url": PRODUCT_FALLBACK,
                                        "width": 64,
                                        "height": 64,
                                        "fit": "cover",
                                    },
                                    "style": {"borderRadius": RADIUS_MD},
                                },
                            },
                        },
                    },
                    {
                        "id": "product-info-block",
                        "type": "container",
                        "style": {"padding": {**PAD_PAGE, "bottom": 8}},
                        "child": {
                            "id": "product-info-col",
                            "type": "column",
                            "props": {"gap": 8, "crossAxis": "start"},
                            "children": [
                                {
                                    "id": "product-info-name",
                                    "type": "text",
                                    "props": {
                                        "valuePath": "dataContext.requests.product-detail.data.name",
                                        "value": "",
                                        "fontSize": 22,
                                        "fontWeight": "bold",
                                        "textAlign": "right",
                                        "color": TEXT,
                                    },
                                },
                                {
                                    "id": "product-info-price",
                                    "type": "text",
                                    "props": {
                                        "valuePath": "dataContext.requests.product-detail.data.displayPrice",
                                        "value": "",
                                        "fontSize": 22,
                                        "fontWeight": "bold",
                                        "textAlign": "right",
                                        "color": PRIMARY,
                                    },
                                },
                                {
                                    "id": "product-info-stock",
                                    "type": "text",
                                    "props": {
                                        "valuePath": "dataContext.requests.product-detail.data.inventory.stockStatus",
                                        "value": "",
                                        "fontSize": 14,
                                        "textAlign": "right",
                                        "color": MUTED,
                                    },
                                },
                            ],
                        },
                    },
                    {"id": "product-divider", "type": "divider", "style": {"margin": PAD_PAGE}},
                    {
                        "id": "product-desc-block",
                        "type": "container",
                        "style": {"padding": {**PAD_PAGE, "bottom": 16}},
                        "child": {
                            "id": "product-desc",
                            "type": "text",
                            "props": {
                                "valuePath": "dataContext.requests.product-detail.data.description",
                                "value": "",
                                "fontSize": 14,
                                "textAlign": "right",
                                "color": MUTED,
                            },
                        },
                    },
                    {
                        "id": "product-cta-block",
                        "type": "container",
                        "style": {"padding": {**PAD_PAGE, "bottom": 24}},
                        "child": {
                            "id": "product-cta-col",
                            "type": "column",
                            "props": {"gap": 10, "crossAxis": "stretch"},
                            "children": [
                                {
                                    "id": "product-add-cart",
                                    "type": "button",
                                    "props": {
                                        "label": "أضف إلى السلة",
                                        "variant": "filled",
                                        "fullWidth": True,
                                    },
                                    "tap": {
                                        "type": "navigate",
                                        "route": "/cart",
                                        "navigation_type": "push",
                                    },
                                },
                                {
                                    "id": "product-add-wishlist",
                                    "type": "button",
                                    "props": {
                                        "label": "أضف إلى المفضلة",
                                        "variant": "outlined",
                                        "fullWidth": True,
                                    },
                                    "tap": {
                                        "type": "navigate",
                                        "route": "/wishlist",
                                        "navigation_type": "push",
                                    },
                                },
                            ],
                        },
                    },
                ],
            },
        }
    ]


def page_category_products() -> list:
    return [
        {
            "id": "category-detail-header",
            "type": "container",
            "props": {
                "data": {
                    "requestKey": "category-detail",
                    "requestUrl": "/api/v1/public/categories/:categorySlug",
                }
            },
            "style": {"padding": {**PAD_PAGE, "top": 12, "bottom": 4}},
            "child": {
                "id": "category-detail-title",
                "type": "text",
                "props": {
                    "valuePath": "dataContext.requests.category-detail.data.name",
                    "value": "",
                    "fontSize": 20,
                    "fontWeight": "bold",
                    "textAlign": "right",
                    "color": TEXT,
                },
            },
        },
        product_grid(
            "category-products-grid",
            "category-products",
            "/api/v1/public/categories/:categorySlug/products?page=0&size=20",
            "dataContext.requests.category-products.data",
        ),
    ]


def cart_line_item(cid: str, name: str, price: str, img_url: str) -> dict:
    return {
        "id": cid,
        "type": "card",
        "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
        "child": {
            "id": f"{cid}-inner",
            "type": "container",
            "style": {"padding": 12},
            "child": {
                "id": f"{cid}-row",
                "type": "row",
                "props": {"gap": 12, "crossAxis": "start"},
                "children": [
                    {
                        "id": f"{cid}-img",
                        "type": "image",
                        "props": {
                            "source": "network",
                            "url": img_url,
                            "width": 72,
                            "height": 72,
                            "fit": "cover",
                        },
                        "style": {"borderRadius": RADIUS_MD},
                    },
                    {
                        "id": f"{cid}-col",
                        "type": "column",
                        "props": {"crossAxis": "start", "gap": 2},
                        "children": [
                            {
                                "id": f"{cid}-name",
                                "type": "text",
                                "props": {
                                    "value": name,
                                    "fontSize": 14,
                                    "fontWeight": "semibold",
                                    "textAlign": "right",
                                    "color": TEXT,
                                },
                            },
                            {
                                "id": f"{cid}-price",
                                "type": "text",
                                "props": {
                                    "value": price,
                                    "fontSize": 15,
                                    "fontWeight": "bold",
                                    "textAlign": "right",
                                    "color": PRIMARY,
                                },
                            },
                            {
                                "id": f"{cid}-qty",
                                "type": "text",
                                "props": {
                                    "value": "الكمية: 1",
                                    "fontSize": 13,
                                    "textAlign": "right",
                                    "color": MUTED,
                                },
                            },
                        ],
                    },
                ],
            },
        },
    }


def page_cart() -> list:
    return [
        {
            "id": "cart-items-col",
            "type": "column",
            "props": {"crossAxis": "stretch", "gap": 10},
            "style": {"padding": {**PAD_PAGE, "top": 12}},
            "children": [
                cart_line_item(
                    "cart-item-1",
                    "حذاء رياضي Pro",
                    "499 ر.س",
                    "https://picsum.photos/seed/cart-1/200/200",
                ),
                cart_line_item(
                    "cart-item-2",
                    "هاتف ذكي X",
                    "2,699 ر.س",
                    "https://picsum.photos/seed/cart-2/200/200",
                ),
            ],
        },
        {
            "id": "cart-summary",
            "type": "card",
            "props": {"color": SURFACE, "borderRadius": RADIUS_MD, "elevation": 0},
            "style": {"margin": {**PAD_PAGE, "top": 16, "bottom": 24}, "padding": 16},
            "child": {
                "id": "cart-summary-col",
                "type": "column",
                "props": {"gap": 8, "crossAxis": "stretch"},
                "children": [
                    {
                        "id": "cart-subtotal-row",
                        "type": "row",
                        "props": {"mainAxis": "spaceBetween"},
                        "children": [
                            {
                                "id": "cart-subtotal-l",
                                "type": "text",
                                "props": {"value": "المجموع الفرعي", "fontSize": 14, "textAlign": "right"},
                            },
                            {
                                "id": "cart-subtotal-v",
                                "type": "text",
                                "props": {"value": "3,198 ر.س", "fontWeight": "medium"},
                            },
                        ],
                    },
                    {
                        "id": "cart-shipping-row",
                        "type": "row",
                        "props": {"mainAxis": "spaceBetween"},
                        "children": [
                            {
                                "id": "cart-ship-l",
                                "type": "text",
                                "props": {"value": "الشحن", "fontSize": 14, "textAlign": "right"},
                            },
                            {
                                "id": "cart-ship-v",
                                "type": "text",
                                "props": {"value": "مجاني", "color": "#16A34A", "fontWeight": "medium"},
                            },
                        ],
                    },
                    {"id": "cart-sum-div", "type": "divider"},
                    {
                        "id": "cart-total-row",
                        "type": "row",
                        "props": {"mainAxis": "spaceBetween"},
                        "children": [
                            {
                                "id": "cart-total-l",
                                "type": "text",
                                "props": {"value": "الإجمالي", "fontSize": 16, "fontWeight": "bold", "textAlign": "right"},
                            },
                            {
                                "id": "cart-total-v",
                                "type": "text",
                                "props": {"value": "3,198 ر.س", "fontSize": 16, "fontWeight": "bold", "color": PRIMARY},
                            },
                        ],
                    },
                    {
                        "id": "cart-checkout-btn",
                        "type": "button",
                        "props": {"label": "متابعة الدفع", "variant": "filled", "fullWidth": True},
                        "tap": {"type": "navigate", "route": "/checkout", "navigation_type": "push"},
                    },
                ],
            },
        },
    ]


def page_checkout_hub() -> list:
    steps = [
        ("checkout-step-address", "1) العنوان", "/checkout/address"),
        ("checkout-step-payment", "2) الدفع", "/checkout/payment"),
    ]
    children = []
    for sid, label, route in steps:
        children.append(
            {
                "id": sid,
                "type": "card",
                "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
                "style": {"margin": {"bottom": 8}},
                "tap": {"type": "navigate", "route": route, "navigation_type": "push"},
                "child": {
                    "id": f"{sid}-inner",
                    "type": "container",
                    "style": {"padding": 16},
                    "child": {
                        "id": f"{sid}-row",
                        "type": "row",
                        "props": {"mainAxis": "spaceBetween", "crossAxis": "center"},
                        "children": [
                            {
                                "id": f"{sid}-label",
                                "type": "text",
                                "props": {"value": label, "fontSize": 15, "fontWeight": "medium", "textAlign": "right"},
                            },
                            {
                                "id": f"{sid}-chev",
                                "type": "icon",
                                "props": {"name": "chevron_left", "size": 22, "color": MUTED},
                            },
                        ],
                    },
                },
            }
        )
    children.append(
        {
            "id": "checkout-place-order",
            "type": "button",
            "props": {"label": "تأكيد الطلب", "variant": "filled", "fullWidth": True},
            "tap": {"type": "navigate", "route": "/order/success", "navigation_type": "clear_stack"},
        }
    )
    return [
        {
            "id": "checkout-steps-wrap",
            "type": "column",
            "props": {"gap": 10, "crossAxis": "stretch"},
            "style": {"padding": 16},
            "children": children,
        }
    ]


def page_search() -> list:
    return [
        {
            "id": "search-field-wrap",
            "type": "container",
            "style": {"padding": {**PAD_PAGE, "top": 12, "bottom": 8}},
            "child": {
                "id": "search-field",
                "type": "textFormField",
                "props": {
                    "id": "searchQuery",
                    "label": "ابحث عن منتج",
                    "hint": "مثال: سماعات، حذاء…",
                    "textAlign": "right",
                    "prefixIcon": "search",
                },
                "style": {
                    "background": SURFACE,
                    "borderRadius": RADIUS_MD,
                    "border": {"width": 1, "color": BORDER},
                },
            },
        },
        {
            "id": "search-autocomplete-list",
            "type": "listView",
            "props": {
                "enableInnerScroll": False,
                "data": {
                    "source": "collection",
                    "id": "search-autocomplete",
                    "requestKey": "search-autocomplete",
                    "requestUrl": "/api/v1/public/products/autocomplete",
                    "qField": "searchQuery",
                },
                "emptyMessage": "لا توجد اقتراحات",
                "errorMessage": "تعذر تحميل الاقتراحات",
            },
            "style": {"padding": {**PAD_PAGE, "bottom": 8}},
            "itemBuilder": {
                "type": "repeat",
                "source": "dataContext.requests.search-autocomplete.data.products",
                "item": {
                    "id": "search-ac-item",
                    "type": "card",
                    "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
                    "style": {"margin": {"bottom": 6}},
                    "child": {
                        "id": "search-ac-row-wrap",
                        "type": "container",
                        "style": {"padding": 10},
                        "child": {
                            "id": "search-ac-row",
                            "type": "row",
                            "props": {"gap": 10, "crossAxis": "center"},
                            "children": [
                                {
                                    "id": "search-ac-thumb",
                                    "type": "image",
                                    "props": {
                                        "source": "network",
                                        "urlPath": "item.image",
                                        "url": PRODUCT_FALLBACK,
                                        "width": 40,
                                        "height": 40,
                                        "fit": "cover",
                                    },
                                    "style": {"borderRadius": 8},
                                },
                                {
                                    "id": "search-ac-name",
                                    "type": "text",
                                    "props": {
                                        "valuePath": "item.name",
                                        "value": "",
                                        "fontSize": 14,
                                        "textAlign": "right",
                                    },
                                },
                            ],
                        },
                    },
                    "tap": {
                        "type": "navigate",
                        "route": "/product/details/:productId",
                        "navigation_type": "push",
                    },
                },
            },
        },
        section_header("search-results-header", "نتائج البحث"),
        product_grid(
            "search-results-grid",
            "search-results",
            "/api/v1/public/products/search?page=0&size=20",
            "dataContext.requests.search-results.data.products",
            q_field="searchQuery",
            collection_id="search-results",
            empty_message="لا توجد نتائج",
            error_message="تعذر تحميل نتائج البحث",
        ),
    ]


def profile_menu_row(rid: str, label: str, icon: str, route: str) -> dict:
    return {
        "id": rid,
        "type": "card",
        "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
        "style": {"margin": {"bottom": 8}},
        "tap": {"type": "navigate", "route": route, "navigation_type": "push"},
        "child": {
            "id": f"{rid}-inner",
            "type": "container",
            "style": {"padding": 14},
            "child": {
                "id": f"{rid}-row",
                "type": "row",
                "props": {"mainAxis": "spaceBetween", "crossAxis": "center"},
                "children": [
                    {
                        "id": f"{rid}-label",
                        "type": "text",
                        "props": {
                            "value": label,
                            "fontSize": 15,
                            "fontWeight": "medium",
                            "textAlign": "right",
                            "color": TEXT,
                        },
                    },
                    {
                        "id": f"{rid}-icons",
                        "type": "row",
                        "props": {"gap": 8, "crossAxis": "center"},
                        "children": [
                            {
                                "id": f"{rid}-icon",
                                "type": "icon",
                                "props": {"name": icon, "size": 22, "color": PRIMARY},
                            },
                            {
                                "id": f"{rid}-chev",
                                "type": "icon",
                                "props": {"name": "chevron_left", "size": 20, "color": MUTED},
                            },
                        ],
                    },
                ],
            },
        },
    }


def state_page(
    pid: str,
    icon: str,
    icon_color: str,
    title: str,
    subtitle: str,
    btn_label: str,
    btn_route: str,
    btn_variant: str = "filled",
) -> list:
    return [
        {
            "id": f"{pid}-root",
            "type": "container",
            "style": {"padding": 24, "expand": True},
            "child": {
                "id": f"{pid}-col",
                "type": "column",
                "props": {"crossAxis": "center", "mainAxis": "center", "gap": 12},
                "children": [
                    {
                        "id": f"{pid}-icon",
                        "type": "icon",
                        "props": {"name": icon, "size": 64, "color": icon_color},
                    },
                    {
                        "id": f"{pid}-title",
                        "type": "text",
                        "props": {
                            "value": title,
                            "fontSize": 22,
                            "fontWeight": "bold",
                            "textAlign": "center",
                            "color": TEXT,
                        },
                    },
                    {
                        "id": f"{pid}-subtitle",
                        "type": "text",
                        "props": {
                            "value": subtitle,
                            "fontSize": 14,
                            "textAlign": "center",
                            "color": MUTED,
                        },
                    },
                    {
                        "id": f"{pid}-btn",
                        "type": "button",
                        "props": {"label": btn_label, "variant": btn_variant, "fullWidth": True},
                        "tap": {
                            "type": "navigate",
                            "route": btn_route,
                            "navigation_type": "clear_stack",
                        },
                    },
                ],
            },
        }
    ]


def component_coverage_body() -> list:
    return [
        {
            "id": "coverage-intro",
            "type": "container",
            "style": {"padding": 16},
            "child": {
                "id": "coverage-intro-text",
                "type": "text",
                "props": {
                    "value": "مرجع أنماط التصميم v2 — انسخ الأقسام إلى صفحات الإنتاج.",
                    "fontSize": 14,
                    "textAlign": "right",
                    "color": MUTED,
                },
            },
        },
        section_header("cov-header-sample", "عنوان قسم", route="/products"),
        {
            "id": "cov-tiles-row-label",
            "type": "text",
            "props": {
                "value": "بلاطة منتج (نموذج)",
                "fontSize": 16,
                "fontWeight": "bold",
                "textAlign": "right",
                "color": TEXT,
            },
            "style": {"padding": PAD_PAGE},
        },
        {
            "id": "cov-product-sample",
            "type": "container",
            "style": {"padding": PAD_PAGE},
            "child": product_tile_item("cov-product-tile"),
        },
        {
            "id": "cov-category-sample",
            "type": "container",
            "style": {"padding": PAD_PAGE},
            "child": category_tile_item("cov-category-tile"),
        },
        {
            "id": "cov-form-sample",
            "type": "form",
            "props": {"formId": "coverage-demo-form"},
            "style": {"padding": PAD_PAGE},
            "child": {
                "id": "cov-form-col",
                "type": "column",
                "props": {"gap": 12, "crossAxis": "stretch"},
                "children": [
                    {
                        "id": "cov-field",
                        "type": "textFormField",
                        "props": {"id": "demo", "label": "حقل نصي", "textAlign": "right"},
                    },
                    {
                        "id": "cov-submit",
                        "type": "button",
                        "props": {"label": "زر أساسي", "variant": "filled", "fullWidth": True},
                    },
                ],
            },
        },
        {
            "id": "cov-primitives",
            "type": "column",
            "props": {"gap": 8, "crossAxis": "stretch"},
            "style": {"padding": PAD_PAGE},
            "children": [
                {"id": "cov-divider", "type": "divider"},
                {"id": "cov-spacer-row", "type": "row", "children": [
                    {"id": "cov-icon", "type": "icon", "props": {"name": "favorite", "color": PRIMARY}},
                    {"id": "cov-spacer", "type": "spacer"},
                    {"id": "cov-pi", "type": "progressIndicator", "props": {"size": 24, "color": PRIMARY}},
                ]},
            ],
        },
    ]


def order_card(oid: str, order_id: str, status: str, status_color: str, total: str) -> dict:
    return {
        "id": oid,
        "type": "card",
        "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
        "style": {"margin": {"bottom": 8}},
        "child": {
            "id": f"{oid}-inner",
            "type": "container",
            "style": {"padding": 14},
            "child": {
                "id": f"{oid}-col",
                "type": "column",
                "props": {"gap": 4, "crossAxis": "start"},
                "children": [
                    {
                        "id": f"{oid}-id",
                        "type": "text",
                        "props": {
                            "value": order_id,
                            "fontSize": 15,
                            "fontWeight": "bold",
                            "textAlign": "right",
                            "color": TEXT,
                        },
                    },
                    {
                        "id": f"{oid}-status",
                        "type": "text",
                        "props": {
                            "value": status,
                            "fontSize": 14,
                            "textAlign": "right",
                            "color": status_color,
                        },
                    },
                    {
                        "id": f"{oid}-total",
                        "type": "text",
                        "props": {
                            "value": total,
                            "fontSize": 14,
                            "textAlign": "right",
                            "color": MUTED,
                        },
                    },
                ],
            },
        },
    }


def page_orders() -> list:
    return [
        {
            "id": "orders-list",
            "type": "listView",
            "props": {"enableInnerScroll": False},
            "style": {"padding": 16},
            "children": [
                order_card("order-1", "#SOQ-7712", "تم الشحن", "#16A34A", "الإجمالي: 1,299 ر.س"),
                order_card("order-2", "#SOQ-7641", "قيد المعالجة", "#D97706", "الإجمالي: 699 ر.س"),
            ],
        }
    ]


def notification_card(nid: str, icon: str, icon_color: str, text: str) -> dict:
    return {
        "id": nid,
        "type": "card",
        "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
        "style": {"margin": {"bottom": 8}},
        "child": {
            "id": f"{nid}-inner",
            "type": "container",
            "style": {"padding": 12},
            "child": {
                "id": f"{nid}-row",
                "type": "row",
                "props": {"gap": 10, "crossAxis": "start"},
                "children": [
                    {
                        "id": f"{nid}-icon",
                        "type": "icon",
                        "props": {"name": icon, "size": 20, "color": icon_color},
                    },
                    {
                        "id": f"{nid}-text",
                        "type": "text",
                        "props": {"value": text, "fontSize": 14, "textAlign": "right", "color": TEXT},
                    },
                ],
            },
        },
    }


def page_notifications() -> list:
    return [
        {
            "id": "notifications-list",
            "type": "listView",
            "props": {"enableInnerScroll": False},
            "style": {"padding": 16},
            "children": [
                notification_card(
                    "notification-1",
                    "local_offer",
                    PRIMARY,
                    "عرض جديد: خصم 20% على الإلكترونيات",
                ),
                notification_card(
                    "notification-2",
                    "local_shipping",
                    "#16A34A",
                    "طلبك #SOQ-7712 خرج للتوصيل",
                ),
            ],
        }
    ]


def page_settings() -> list:
    rows = [
        ("settings-language", "اللغة"),
        ("settings-currency", "العملة"),
        ("settings-notification", "تفضيلات الإشعارات"),
    ]
    children = []
    for sid, label in rows:
        children.append(
            {
                "id": sid,
                "type": "button",
                "props": {
                    "label": label,
                    "variant": "outlined",
                    "fullWidth": True,
                },
            }
        )
    children.append(
        {
            "id": "settings-logout",
            "type": "button",
            "props": {"label": "تسجيل خروج", "variant": "outlined", "fullWidth": True, "textColor": "#DC2626"},
            "tap": {
                "type": "cubitCall",
                "cubit": "auth",
                "method": "logout",
                "onSuccess": {
                    "type": "navigate",
                    "route": "/auth/login",
                    "navigation_type": "clear_stack",
                },
            },
        }
    )
    return [
        {
            "id": "settings-list",
            "type": "column",
            "props": {"gap": 10, "crossAxis": "stretch"},
            "style": {"padding": 16},
            "children": children,
        }
    ]


def page_support() -> list:
    return [
        {
            "id": "support-content",
            "type": "column",
            "props": {"gap": 10, "crossAxis": "stretch"},
            "style": {"padding": 16},
            "children": [
                {
                    "id": "support-faq-1",
                    "type": "card",
                    "props": {"color": SURFACE, "borderRadius": RADIUS_MD, "elevation": 0},
                    "child": {
                        "id": "support-faq-1-col",
                        "type": "column",
                        "props": {"gap": 6, "crossAxis": "start"},
                        "style": {"padding": 14},
                        "children": [
                            {
                                "id": "support-faq-1-q",
                                "type": "text",
                                "props": {
                                    "value": "كيف أتابع طلبي؟",
                                    "fontSize": 15,
                                    "fontWeight": "bold",
                                    "textAlign": "right",
                                },
                            },
                            {
                                "id": "support-faq-1-a",
                                "type": "text",
                                "props": {
                                    "value": "من صفحة طلباتي داخل حسابك.",
                                    "fontSize": 14,
                                    "textAlign": "right",
                                    "color": MUTED,
                                },
                            },
                        ],
                    },
                },
                {
                    "id": "support-contact-cta",
                    "type": "button",
                    "props": {"label": "تواصل مع الدعم", "variant": "filled", "fullWidth": True},
                    "tap": {"type": "openUrl", "url": "https://sooq.support"},
                },
            ],
        }
    ]


def page_state_loading() -> list:
    return [
        {
            "id": "state-loading-root",
            "type": "column",
            "props": {"gap": 12, "crossAxis": "stretch"},
            "style": {"padding": 16},
            "children": [
                {
                    "id": "state-loading-banner",
                    "type": "container",
                    "style": {
                        "height": 120,
                        "background": BORDER,
                        "borderRadius": RADIUS_LG,
                    },
                },
                {
                    "id": "state-loading-row",
                    "type": "row",
                    "props": {"gap": 10},
                    "children": [
                        {
                            "id": "sk-1",
                            "type": "container",
                            "style": {
                                "width": 160,
                                "height": 200,
                                "background": BORDER,
                                "borderRadius": RADIUS_MD,
                            },
                        },
                        {
                            "id": "sk-2",
                            "type": "container",
                            "style": {
                                "width": 160,
                                "height": 200,
                                "background": BORDER,
                                "borderRadius": RADIUS_MD,
                            },
                        },
                    ],
                },
                {
                    "id": "state-loading-center",
                    "type": "column",
                    "props": {"crossAxis": "center", "gap": 12},
                    "children": [
                        {
                            "id": "state-loading-pi",
                            "type": "progressIndicator",
                            "props": {"color": PRIMARY, "size": 32},
                        },
                        {
                            "id": "state-loading-text",
                            "type": "text",
                            "props": {
                                "value": "جاري تحميل البيانات…",
                                "fontSize": 14,
                                "textAlign": "center",
                                "color": MUTED,
                            },
                        },
                    ],
                },
            ],
        }
    ]


def checkout_address_body() -> list:
    return [
        {
            "id": "address-form",
            "type": "form",
            "props": {"formId": "checkout-address-form"},
            "style": {"padding": 16},
            "child": {
                "id": "address-form-col",
                "type": "column",
                "props": {"gap": 12, "crossAxis": "stretch"},
                "children": [
                    {
                        "id": "address-field-name",
                        "type": "textFormField",
                        "props": {
                            "id": "fullName",
                            "label": "الاسم الكامل",
                            "textAlign": "right",
                            "validateRequired": True,
                        },
                    },
                    {
                        "id": "address-field-phone",
                        "type": "textFormField",
                        "props": {
                            "id": "phone",
                            "label": "رقم الجوال",
                            "keyboardType": "phone",
                            "textAlign": "right",
                            "validateRequired": True,
                        },
                    },
                    {
                        "id": "address-field-line",
                        "type": "textFormField",
                        "props": {
                            "id": "addressLine",
                            "label": "العنوان",
                            "textAlign": "right",
                            "validateRequired": True,
                        },
                    },
                    {
                        "id": "address-continue",
                        "type": "button",
                        "props": {"label": "متابعة للدفع", "variant": "filled", "fullWidth": True},
                        "tap": {
                            "type": "navigate",
                            "route": "/checkout/payment",
                            "navigation_type": "push",
                            "requireValidForm": True,
                            "formId": "checkout-address-form",
                        },
                    },
                ],
            },
        }
    ]


def checkout_payment_body() -> list:
    methods = [
        ("payment-card-option", "بطاقة ائتمان", "credit_card"),
        ("payment-cod-option", "الدفع عند الاستلام", "payments"),
    ]
    children = []
    for mid, label, icon in methods:
        children.append(
            {
                "id": mid,
                "type": "card",
                "props": {"color": WHITE, "borderRadius": RADIUS_MD, "elevation": 0},
                "style": {"margin": {"bottom": 8}},
                "child": {
                    "id": f"{mid}-inner",
                    "type": "container",
                    "style": {"padding": 14},
                    "child": {
                        "id": f"{mid}-row",
                        "type": "row",
                        "props": {"mainAxis": "spaceBetween", "crossAxis": "center"},
                        "children": [
                            {
                                "id": f"{mid}-label",
                                "type": "text",
                                "props": {
                                    "value": label,
                                    "fontSize": 15,
                                    "fontWeight": "semibold",
                                    "textAlign": "right",
                                },
                            },
                            {
                                "id": f"{mid}-icon",
                                "type": "icon",
                                "props": {"name": icon, "size": 22, "color": PRIMARY},
                            },
                        ],
                    },
                },
            }
        )
    children.append(
        {
            "id": "payment-confirm",
            "type": "button",
            "props": {"label": "تأكيد الدفع", "variant": "filled", "fullWidth": True},
            "tap": {
                "type": "navigate",
                "route": "/order/success",
                "navigation_type": "clear_stack",
            },
        }
    )
    return [
        {
            "id": "payment-methods",
            "type": "column",
            "props": {"gap": 10, "crossAxis": "stretch"},
            "style": {"padding": 16},
            "children": children,
        }
    ]


def order_status_page(
    pid: str, success: bool, title: str, subtitle: str, primary_route: str, primary_label: str
) -> list:
    color = "#16A34A" if success else "#DC2626"
    icon = "check_circle" if success else "cancel"
    return [
        {
            "id": f"{pid}-root",
            "type": "container",
            "style": {"padding": 24},
            "child": {
                "id": f"{pid}-col",
                "type": "column",
                "props": {"crossAxis": "center", "gap": 12},
                "children": [
                    {
                        "id": f"{pid}-icon",
                        "type": "icon",
                        "props": {"name": icon, "size": 72, "color": color},
                    },
                    {
                        "id": f"{pid}-title",
                        "type": "text",
                        "props": {
                            "value": title,
                            "fontSize": 22,
                            "fontWeight": "bold",
                            "textAlign": "center",
                            "color": TEXT,
                        },
                    },
                    {
                        "id": f"{pid}-sub",
                        "type": "text",
                        "props": {
                            "value": subtitle,
                            "fontSize": 14,
                            "textAlign": "center",
                            "color": MUTED,
                        },
                    },
                    {
                        "id": f"{pid}-primary",
                        "type": "button",
                        "props": {"label": primary_label, "variant": "filled", "fullWidth": True},
                        "tap": {
                            "type": "navigate",
                            "route": primary_route,
                            "navigation_type": "clear_stack",
                        },
                    },
                ],
            },
        }
    ]


PAGE_BODIES: dict[str, list] = {
    "/home": page_home,
    "/categories": page_categories_list,
    "/products": page_products,
    "/product/details/:productId": page_product_detail,
    "/categories/:categorySlug/products": page_category_products,
    "/search": page_search,
    "/cart": page_cart,
    "/checkout": page_checkout_hub,
    "/checkout/address": checkout_address_body,
    "/checkout/payment": checkout_payment_body,
    "/order/success": lambda: order_status_page(
        "order-success",
        True,
        "تم تأكيد طلبك",
        "شكراً لتسوقك معنا. سنرسل لك تحديثات التوصيل.",
        "/home",
        "العودة للرئيسية",
    ),
    "/order/failure": lambda: order_status_page(
        "order-failure",
        False,
        "تعذر إتمام الطلب",
        "حاول مرة أخرى أو اختر طريقة دفع أخرى.",
        "/checkout/payment",
        "إعادة المحاولة",
    ),
    "/orders": page_orders,
    "/notifications": page_notifications,
    "/settings": page_settings,
    "/support": page_support,
    "/state/loading": page_state_loading,
    "/state/empty": lambda: state_page(
        "state-empty",
        "inventory_2",
        MUTED,
        "لا توجد عناصر",
        "جرّب التصفح أو البحث عن منتجات جديدة.",
        "اذهب للتسوق",
        "/home",
    ),
    "/state/error": lambda: state_page(
        "state-error",
        "error_outline",
        "#DC2626",
        "حدث خطأ",
        "تعذر تحميل المحتوى. تحقق من الاتصال وحاول مجدداً.",
        "العودة للرئيسية",
        "/home",
    ),
    "/component-coverage": component_coverage_body,
}


def set_page_body(pages: list, route: str, body: list) -> None:
    for p in pages:
        if p.get("route") == route:
            p["body"] = body
            p["background"] = BG
            if "appBar" in p:
                ab = p["appBar"]
                if isinstance(ab, dict) and "style" not in ab:
                    ab["style"] = {"background": WHITE}
            return
    raise KeyError(route)


def polish_auth_buttons(node: dict) -> None:
    """Primary auth CTAs: filled + fullWidth."""
    if not isinstance(node, dict):
        return
    if node.get("id") in ("auth-login-submit", "auth-otp-submit"):
        props = node.setdefault("props", {})
        props["variant"] = "filled"
        props["fullWidth"] = True
        props.pop("backgroundColor", None)
        props.pop("textColor", None)
        props.pop("maxWidth", None)
    for k in ("body", "child", "children"):
        v = node.get(k)
        if isinstance(v, dict):
            polish_auth_buttons(v)
        elif isinstance(v, list):
            for c in v:
                if isinstance(c, dict):
                    polish_auth_buttons(c)


def polish_splash_carousel_cta(pages: list) -> None:
    for p in pages:
        if p.get("route") != "/splash-carousel":
            continue
        stack = [p]
        while stack:
            n = stack.pop()
            if isinstance(n, dict):
                if n.get("id") == "splash-carousel-start":
                    n["props"] = {
                        "label": "لنبدأ",
                        "variant": "filled",
                        "fullWidth": True,
                    }
                for k in ("body", "child", "children"):
                    v = n.get(k)
                    if isinstance(v, dict):
                        stack.append(v)
                    elif isinstance(v, list):
                        stack.extend(x for x in v if isinstance(x, dict))


def main() -> None:
    with CONFIG_PATH.open(encoding="utf-8") as f:
        data = json.load(f)

    pages = data["pages"]

    for route, factory in PAGE_BODIES.items():
        body = factory() if callable(factory) else factory
        set_page_body(pages, route, body)

    for p in pages:
        if p.get("route") in ("/auth/login", "/auth/otp-reset"):
            polish_auth_buttons(p)

    polish_splash_carousel_cta(pages)

    # Global aspect ratio pass on remaining grids
    for p in pages:
        stack = [p]
        while stack:
            node = stack.pop()
            if isinstance(node, dict):
                props = node.get("props") or {}
                if node.get("type") == "gridView" and "childAspectRatio" in props:
                    rk = (props.get("data") or {}).get("requestKey", "")
                    if "categor" in rk and "products" not in rk:
                        props["childAspectRatio"] = 0.75
                    else:
                        props["childAspectRatio"] = 0.68
                for k in ("body", "child", "children", "item"):
                    v = node.get(k)
                    if isinstance(v, dict):
                        stack.append(v)
                    elif isinstance(v, list):
                        stack.extend(v)
                ib = node.get("itemBuilder")
                if isinstance(ib, dict) and "item" in ib:
                    stack.append(ib["item"])

    # Profile menu
    for p in pages:
        if p.get("route") == "/profile":
            p["body"] = [
                {
                    "id": "profile-header",
                    "type": "container",
                    "style": {
                        "padding": 20,
                        "margin": {**PAD_PAGE, "top": 12, "bottom": 8},
                        "background": WHITE,
                        "borderRadius": RADIUS_LG,
                    },
                    "child": {
                        "id": "profile-header-col",
                        "type": "column",
                        "props": {"gap": 4, "crossAxis": "start"},
                        "children": [
                            {
                                "id": "profile-greeting",
                                "type": "text",
                                "props": {
                                    "value": "مرحباً بك",
                                    "fontSize": 22,
                                    "fontWeight": "bold",
                                    "textAlign": "right",
                                    "color": TEXT,
                                },
                            },
                            {
                                "id": "profile-sub",
                                "type": "text",
                                "props": {
                                    "value": "إدارة طلباتك ومفضلتك من مكان واحد",
                                    "fontSize": 14,
                                    "textAlign": "right",
                                    "color": MUTED,
                                },
                            },
                        ],
                    },
                },
                {
                    "id": "profile-menu",
                    "type": "column",
                    "props": {"gap": 0, "crossAxis": "stretch"},
                    "style": {"padding": PAD_PAGE},
                    "children": [
                        profile_menu_row("profile-orders", "طلباتي", "receipt_long", "/orders"),
                        profile_menu_row("profile-wishlist", "المفضلة", "favorite", "/wishlist"),
                        profile_menu_row(
                            "profile-notifications",
                            "الإشعارات",
                            "notifications",
                            "/notifications",
                        ),
                        profile_menu_row("profile-settings", "الإعدادات", "settings", "/settings"),
                        profile_menu_row("profile-support", "الدعم", "help_outline", "/support"),
                    ],
                },
            ]
            break

    # Wishlist grid uses standard product tile
    for p in pages:
        if p.get("route") == "/wishlist":
            p["body"] = [
                product_grid(
                    "wishlist-grid",
                    "wishlist-products",
                    "/api/v1/public/products?page=0&size=20",
                    "dataContext.requests.wishlist-products.data",
                )
            ]
            break

    with CONFIG_PATH.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Updated {CONFIG_PATH}")


if __name__ == "__main__":
    main()
