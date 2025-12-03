#!/bin/bash
# HypeHere Deployment Script
# This script prepares the application for deployment to AWS App Runner

set -e  # Exit on any error

echo "🚀 Starting HypeHere deployment preparation..."
echo ""

# Check if required environment variables are set
check_env_vars() {
    local required_vars=(
        "DEBUG"
        "DJANGO_SECRET_KEY"
        "DATABASE_URL"
        "REDIS_URL"
        "AWS_STORAGE_BUCKET_NAME"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "❌ Error: The following required environment variables are not set:"
        printf '  - %s\n' "${missing_vars[@]}"
        echo ""
        echo "Please set these variables before running this script."
        exit 1
    fi

    echo "✅ All required environment variables are set"
}

# Collect static files and upload to S3
collect_static() {
    echo ""
    echo "📦 Collecting static files and uploading to S3..."
    python manage.py collectstatic --noinput
    echo "✅ Static files collected successfully"
}

# Run database migrations
run_migrations() {
    echo ""
    echo "🗄️ Running database migrations..."
    python manage.py migrate --noinput
    echo "✅ Database migrations completed"
}

# Create superuser (optional, only in development)
create_superuser() {
    if [ "$DEBUG" = "True" ]; then
        echo ""
        echo "👤 Creating superuser (development only)..."
        python manage.py shell << 'EOF'
from accounts.models import User
if not User.objects.filter(email='admin@example.com').exists():
    User.objects.create_superuser(
        email='admin@example.com',
        nickname='Admin',
        password='changeme123'
    )
    print("Superuser created: admin@example.com")
else:
    print("Superuser already exists")
EOF
        echo "✅ Superuser check completed"
    fi
}

# Main deployment flow
main() {
    echo "=== Phase 1: Environment Check ==="
    check_env_vars

    echo ""
    echo "=== Phase 2: Static Files ==="
    collect_static

    echo ""
    echo "=== Phase 3: Database Setup ==="
    run_migrations

    echo ""
    echo "=== Phase 4: Superuser Setup ==="
    create_superuser

    echo ""
    echo "✅ Deployment preparation completed successfully!"
    echo ""
    echo "🎉 Your application is ready to be deployed!"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure your code is pushed to GitHub"
    echo "  2. Configure AWS App Runner service"
    echo "  3. Set environment variables in App Runner console"
    echo "  4. Deploy and monitor the logs"
}

# Run main function
main
