from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["public"])


def _page(title: str, body: str) -> HTMLResponse:
    return HTMLResponse(
        f"""<!doctype html><html lang=\"zh-CN\"><head><meta charset=\"utf-8\">
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>{title}</title>
<style>body{{max-width:760px;margin:40px auto;padding:0 20px;font:16px/1.7 system-ui;color:#3b2d28}}
h1{{font-size:28px}}a{{color:#c55b4b}}</style></head><body><h1>{title}</h1>{body}</body></html>"""
    )


@router.get("/account-deletion", response_class=HTMLResponse)
async def account_deletion_page() -> HTMLResponse:
    return _page(
        "智能记账账号删除",
        """<p>在 Android App 中进入“账号与安全 → 注销账号”，提交并二次确认。</p>
<p>确认后将撤销登录会话、删除认证身份并解除匿名运营数据与账号的关联。账本目前仅保存在设备上，
用户可选择删除本地账本或保留为隔离文件。</p>
<p>必要的去标识化安全审计可能按法律要求保留；工程目标处理时间为 7 个自然日内。</p>
<p>支持联系：请在正式上架前配置公开支持邮箱。</p>""",
    )


@router.get("/privacy", response_class=HTMLResponse)
async def privacy_page() -> HTMLResponse:
    return _page(
        "智能记账隐私政策（待法律审核草案）",
        "<p>本页面将在正式上架前替换为完成主体信息、联系方式和法律审核的正式文本。</p>",
    )


@router.get("/terms", response_class=HTMLResponse)
async def terms_page() -> HTMLResponse:
    return _page(
        "智能记账用户协议（待法律审核草案）",
        "<p>本页面将在正式上架前替换为完成主体信息、联系方式和法律审核的正式文本。</p>",
    )
