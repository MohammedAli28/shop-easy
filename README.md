# 🛍️ Shop Easy — E-Commerce Microservices

> Full-featured microservices e-commerce app on AWS ECS Fargate with Stripe payments, admin dashboard, category management, customer portal, and Grafana-style analytics. 1-click deploy via GitHub Actions.

---

## Architecture

![Shop Easy Architecture](https://github.com/aniljadhavmca/shop-easy/blob/feature/stripe-monitoring/docs/flow.png)

---

## Services (3 Fargate Tasks)

| Service | Port | Handles | Tech |
|---------|------|---------|------|
| Frontend | 80 | UI — shop, cart, checkout, admin panel, customer portal | React + Recharts + Stripe Elements + Nginx |
| Product Service | 4001 | Products CRUD + Cart + Categories | Node.js/Express |
| Order Service | 4002 | Orders + Payments + Auth + Analytics | Node.js/Express + Stripe SDK |

---

## Features

### Customer Experience
- **Hero banner** — Dark gradient with promotional text and CTA buttons
- **Category navigation** — Flipkart-style icon strip with arrow navigation (scrollable)
- **Product catalog** — 4-column grid, star ratings, category filters
- **Search** — Real-time search by product name or category
- **Hot Deals** — 4 random products with SALE badge and strikethrough pricing
- **Trending slider** — Auto-scrolling product carousel
- **Product detail modal** — Full description, ratings, customer reviews (Flipkart-style)
- **Shopping cart** — Add/remove items, quantity display
- **Checkout** — Name, email, phone, address + Stripe card payment (billing details sent to Stripe)
- **My Orders** — Email-based login, order history with progress tracker (Ordered → Paid → Shipped → Delivered)
- **Receipts** — Printable order receipts with full payment details
- **Trust bar** — Free Shipping, Secure Payment, Easy Returns, Top Quality
- **Promo banner** — Flash deal promotional section
- **Mobile responsive** — Hamburger menu with flyout navigation
- **Back to top** — Floating button on scroll

### Admin Panel (Protected — no header, full-screen layout)
- **Login** — Username/password authentication (`admin` / `ShopEasy2026`)
- **Dashboard** — Stats cards (📊 Total Orders, 💰 Paid, 🚨 Failed, 🚀 Products Live)
- **Grafana-style charts** — Revenue Over Time (area chart) + Revenue Breakdown (bar chart)
- **Revenue** includes paid + shipped + delivered orders
- **Time range selector** — 10m, 1h, 4h, 6h, 12h, 1d, 3d
- **Products CRUD** — Add/edit/delete products on dedicated form page, category dropdown
- **Categories management** — Add/edit/delete categories with custom icon URLs, product count per category
- **Orders management** — Filter by status (All/Paid/Pending/Failed/Shipped/Delivered), update status
- **Logout** — Session-based admin auth

---

## 1-Click Deploy to AWS

### Prerequisites
- AWS account with `AdministratorAccess` IAM user
- GitHub repo forked/cloned

### Setup (once)

Add **5 secrets** to your GitHub repo → Settings → Secrets → Actions:

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |
| `DB_PASSWORD` | Any password — letters + numbers only (e.g. `ShopEasy2024Strong`) |
| `STRIPE_SECRET_KEY` | Stripe test secret key (`sk_test_...`) |
| `STRIPE_PUBLISHABLE_KEY` | Stripe test publishable key (`pk_test_...`) |

### Deploy

1. Go to **Actions** → **🚀 Deploy Shop Easy**
2. Click **Run workflow** → select `deploy`
3. Wait ~15 min → get ALB URL in the summary ✅

### What happens automatically:
```
Step 1: Creates S3 bucket for Terraform state
Step 2: Provisions AWS infra (VPC, ALB, ECS, RDS, ECR, CloudWatch Dashboard)
Step 3: Builds Docker images (linux/amd64)
Step 4: Pushes images to ECR
Step 5: Runs db-init ECS task (loads schema + seed data)
Step 6: Deploys 3 services to ECS Fargate (sequential, 30s gaps)
Step 7: Outputs ALB URL + Dashboard URL ✅
```

### Destroy

Same workflow → select `destroy` → all resources + state bucket deleted.

---

## Run Locally

```bash
# Set Stripe test keys in .env
cat > .env << EOF
STRIPE_SECRET_KEY=sk_test_your_key
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_your_key
EOF

docker compose up --build
```

Open http://localhost:3000

- **Admin Panel:** Click Admin → Login with `admin` / `ShopEasy2026`
- **My Orders:** Click My Orders → Enter the email used during checkout
- **Test card:** `4242 4242 4242 4242` | Any future expiry | Any CVC

---

## Test Cards (Stripe)

| Card Number | Result |
|-------------|--------|
| `4242 4242 4242 4242` | Payment succeeds ✅ |
| `4000 0000 0000 0002` | Card declined ❌ |
| `4000 0000 0000 9995` | Insufficient funds ❌ |
| `4000 0000 0000 0069` | Expired card ❌ |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, Recharts, Stripe Elements, Nginx |
| Backend | Node.js, Express, Stripe SDK |
| Database | MySQL 8.0 (RDS) |
| Payments | Stripe (test mode) |
| Charts | Recharts (Grafana-style analytics) |
| Icons | Icons8 Fluency (CDN) |
| Monitoring | CloudWatch Dashboard + Logs Insights |
| Containers | Docker, ECS Fargate |
| Networking | VPC, ALB, NAT Gateway |
| Registry | Amazon ECR |
| State | S3 (auto-created) |
| IaC | Terraform |
| CI/CD | GitHub Actions |

---

## Project Structure

```
shop-easy/
├── frontend/           # React SPA + Nginx (shop, admin, customer portal)
├── product-service/    # Products CRUD + Cart + Categories API
├── order-service/      # Orders + Payments + Auth + Analytics API
├── db-init/            # DB migration container (runs once)
├── database/           # SQL schema + seed data (15 products, 11 categories)
├── terraform/          # AWS infra (VPC, ECS, RDS, ALB, CloudWatch)
├── .github/workflows/  # 1-click CI/CD pipeline
├── docs/               # Architecture diagrams + documentation
├── docker-compose.yml  # Local development
└── .env                # Local Stripe keys (gitignored)
```

---

## Database Schema

| Table | Purpose |
|-------|---------|
| `categories` | Category name, icon, image URL |
| `products` | Name, description, price, image, category, stock |
| `users` | Email, name |
| `cart_items` | User cart (user_id, product_id, quantity) |
| `orders` | Order with shipping details + status |
| `order_items` | Products in each order |
| `payments` | Payment records (amount, status, method) |

---

## API Endpoints

### Product Service (port 4001)
| Method | Path | Description |
|--------|------|-------------|
| GET | /products | List all products |
| GET | /products/:id | Get product |
| POST | /products | Create product (admin) |
| PUT | /products/:id | Update product (admin) |
| DELETE | /products/:id | Delete product (admin) |
| GET | /categories | List all categories |
| POST | /categories | Create category (admin) |
| PUT | /categories/:id | Update category (admin) |
| DELETE | /categories/:id | Delete category (admin) |
| GET | /cart/:userId | Get cart items |
| POST | /cart | Add to cart |
| DELETE | /cart/:id | Remove from cart |

### Order Service (port 4002)
| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/admin | Admin login |
| GET | /orders/stats/summary | Dashboard stats |
| GET | /orders/stats/timeseries | Revenue chart data (query: ?minutes=60) |
| GET | /orders/all | All orders (admin) |
| GET | /orders/by-email/:email | Customer orders |
| GET | /orders/:userId | User orders |
| POST | /orders | Create order |
| PUT | /orders/:id/status | Update order status (admin) |
| POST | /payments/create-intent | Stripe payment intent |
| POST | /payments/confirm | Confirm payment |
| POST | /payments/failed | Log failed payment |

---

## User Flow

1. **Browse** — Hero banner → Category strip → Product grid with search
2. **Filter** — Click category or search by name/category
3. **View** — Click product → Modal with details, ratings, reviews
4. **Cart** — Add items, view cart, proceed to checkout
5. **Pay** — Fill shipping details + Stripe card → Payment processed
6. **Track** — My Orders → Email login → Order progress tracker + receipts
7. **Admin** — Login → Dashboard → Manage products, categories, orders

---

## Default Categories (11)

| Category | Icon |
|----------|------|
| Mobile | 📱 |
| Laptop | 💻 |
| Television | 📺 |
| Earpods | 🎧 |
| Kitchen | 🍳 |
| Accessories | ⌚ |
| Cameras | 📷 |
| Fans | 🌀 |
| Grooming | 💈 |
| Storage | 💾 |
| Air Conditioners | ❄️ |

---

## Cost (~$89/month)

| Resource | Cost |
|----------|------|
| ECS Fargate (3 tasks) | ~$25 |
| NAT Gateway | ~$32 |
| RDS db.t3.micro | ~$15 |
| ALB | ~$16 |
| ECR + S3 | ~$1 |
| **Total** | **~$89/month** |

---

## Monitoring (CloudWatch Dashboard)

Auto-provisioned via Terraform:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=shop-easy-orders
```

### Structured Log Events

| Event | Trigger | Fields |
|-------|---------|--------|
| `ORDER_PENDING` | Order created | order_id, user_id, amount, customer, email, reason |
| `ORDER_BOOKED` | Payment succeeded | order_id, user_id, amount, customer, email, reason |
| `ORDER_FAILED` | Payment failed | order_id, user_id, amount, reason, stripe_status |
| `ORDER_ERROR` | Exception | order_id, error |

---

## Security

- ECS tasks in **private subnets** — no public IPs
- RDS in **private subnets** (`publicly_accessible = false`)
- NAT Gateway provides outbound-only internet access (ECR pulls, Stripe API)
- ALB is the only internet-facing resource (public subnets, port 80)
- ECS security group allows inbound only from ALB
- Admin panel protected by username/password authentication
- DB password stored as GitHub Secret — never in code
- Stripe keys stored as GitHub Secrets — never in code
- Terraform state encrypted in S3 with versioning
- Stripe test mode — no real charges

---

## Credits

© 2026 ShopEasy. Proudly built by **Anil Jadhav**
