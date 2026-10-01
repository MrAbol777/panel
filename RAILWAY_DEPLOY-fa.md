# استقرار پنل PasarGuard روی Railway

این راهنما برای سرویس وب و داشبورد این fork است. Dockerfile در زمان **ساخت image**، وابستگی‌های Bun را نصب و خروجی `dashboard/build` را تولید می‌کند؛ در زمان اجرای کانتینر نیازی به اجرای دستی `build_dashboard.sh` نیست.

## راه‌اندازی

1. تغییرات این پوشه را در مخزن `abolfazl9774/panel` ثبت و push کنید. در Railway یک پروژه بسازید، سرویس GitHub را به همین مخزن و شاخه متصل کنید و Root Directory را روی ریشه مخزن بگذارید. Builder باید Dockerfile ریشه را استفاده کند.
2. یک سرویس PostgreSQL به همان پروژه اضافه کنید. در Variables سرویس پنل، مقدار زیر را تنظیم کنید (اگر نام سرویس پایگاه داده `Postgres` نیست، نام مرجع را تغییر دهید):

   ```text
   SQLALCHEMY_DATABASE_URL=postgresql+asyncpg://${{Postgres.PGUSER}}:${{Postgres.PGPASSWORD}}@${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}
   ```

3. برای سرویس پنل `ROLE=all-in-one`، `DEBUG=false` یا حذف `DEBUG`، `UVICORN_HOST=0.0.0.0` و `DASHBOARD_PATH=/dashboard/` را تنظیم کنید. `PORT` را به مقدار ثابت قفل نکنید؛ برنامه اکنون از `PORT` خود Railway می‌خواند. اگر `UVICORN_PORT` از قبل تنظیم شده، آن را حذف کنید تا با `PORT` تداخل نکند. `VITE_BASE_API` را برای همین سرویس روی مقدار پیش‌فرض `/` نگه دارید.
4. در Settings → Networking برای سرویس پنل یک دامنه HTTPS بسازید. در Settings → Deploy مقدار Healthcheck Path را `/dashboard/` بگذارید. فایل `start.sh` پیش از بالا آمدن برنامه migrationهای Alembic را اجرا می‌کند.
5. پس از deploy، آدرس‌های `https://YOUR_DOMAIN/health` و `https://YOUR_DOMAIN/dashboard/` را بررسی کنید. برای ساخت کلید یک‌بارمصرف حساب owner، در ترمینال سرویس Railway دستور `pasarguard-cli generate-temp-key` را اجرا کنید و کلید را در صفحه ورود داشبورد وارد کنید. کلید را در لاگ یا پیام عمومی منتشر نکنید.

## داده و محدودیت شبکه

- پایگاه داده پیش‌فرض SQLite در فایل‌سیستم موقت کانتینر قرار می‌گیرد و با redeploy از دست می‌رود؛ برای استفاده واقعی، PostgreSQL بالا را حتماً متصل کنید. اگر فایل‌های دیگری در برنامه ایجاد می‌کنید، مسیرشان را پیش از استفاده به Volume پایدار منتقل کنید.
- دامنه HTTP(S) Railway فقط دسترسی وب پنل و API را فراهم می‌کند. برای inboundهای Xray/WireGuard و پورت‌های TCP/UDP دلخواه، شبکه و قابلیت‌های Railway را برای هر پروتکل جداگانه بررسی کنید؛ بالا آمدن داشبورد به معنی کارکرد این ترافیک‌ها نیست.
- گواهی HTTPS را Railway در لبه شبکه مدیریت می‌کند. تنظیم `UVICORN_SSL_CERTFILE` و `UVICORN_SSL_KEYFILE` در کانتینر لازم نیست. این رفتار فقط وقتی `RAILWAY_SERVICE_ID` در محیط وجود دارد فعال می‌شود.

## بررسی خطا

- اگر `/health` باز نمی‌شود، Build Logs را برای خطای Bun/uv و Deploy Logs را برای خطای migration یا پایگاه داده ببینید.
- اگر `/health` سالم ولی `/dashboard/` خطا دارد، وجود `dashboard/build/index.html` در image و `DEBUG=false` را بررسی کنید.
- اگر صفحه باز می‌شود ولی درخواست‌های API خطا دارند، Network مرورگر و آدرس `VITE_BASE_API` را بررسی کنید؛ مقدار مناسب برای پنل و API در یک سرویس `/` است.
