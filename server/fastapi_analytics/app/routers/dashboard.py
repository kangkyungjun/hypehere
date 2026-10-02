from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")


@router.get("/dashboard", response_class=HTMLResponse)
def dashboard(request: Request):
    """
    Public analytics dashboard.

    **Mobile-friendly web interface** for:
    - Top/Bottom performing tickers
    - Ticker search with score charts
    - Historical data visualization

    Accessible at: https://hypehere.net/dashboard
    """
    return templates.TemplateResponse("dashboard.html", {"request": request})
