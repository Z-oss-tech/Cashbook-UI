# Cashbook Backend API Documentation

This is the backend for the Cashbook Flutter Application, built with Node.js, Express, PostgreSQL, and Prisma ORM.

## Tech Stack
- **Node.js** & **Express.js**: REST API Framework
- **PostgreSQL**: Relational Database
- **Prisma ORM**: Database interaction and migrations
- **JWT**: Authentication
- **Cloudinary**: File/Image Storage (configured for avatars/attachments)

## Setup & Run Locally
1. Clone this repository
2. Ensure you have Node.js and PostgreSQL installed.
3. Install dependencies:
   ```bash
   npm install
   ```
4. Configure `.env`:
   Create a `.env` file based on `.env.example` and set your `DATABASE_URL`, `JWT_SECRET`, and Cloudinary variables.
5. Apply database migrations:
   ```bash
   npx prisma db push
   # or
   npx prisma migrate dev
   ```
6. Start the development server:
   ```bash
   npm run dev
   ```

## Production Deployment (Render/Railway/DigitalOcean)
- A `Dockerfile` and `.dockerignore` are provided for containerized deployment.
- Ensure to set `DATABASE_URL` and `JWT_SECRET` in your hosting provider's environment variables.
- Run `npx prisma generate` and `npx prisma migrate deploy` during the build step.

---

## API Endpoints

### Authentication (`/api/auth`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/send-otp` | Send OTP to phone | No |
| `POST` | `/verify-otp` | Verify OTP and login/register | No |
| `GET` | `/profile` | Get current user profile | Yes |
| `PUT` | `/profile` | Update current user profile | Yes |

### Cashbooks (`/api/cashbooks`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/` | List all cashbooks for the user | Yes |
| `POST` | `/` | Create a new cashbook | Yes |
| `GET` | `/:id` | Get cashbook details & records | Yes |
| `PUT` | `/:id` | Update cashbook | Yes |
| `DELETE`| `/:id` | Archive/Delete cashbook | Yes |

### Records (`/api/records`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/?cashbookId={id}` | List records for a cashbook | Yes |
| `POST` | `/` | Create a new record (income/expense) | Yes |
| `PUT` | `/:id` | Update an existing record | Yes |
| `DELETE`| `/:id` | Soft delete a record | Yes |

### Uploads (`/api/upload`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/` | Upload an image (form-data: `image`) | Yes |
| `DELETE`| `/` | Delete an image by `public_id` | Yes |

---

## Database Schema (Prisma)

- **User**: Stores user details (id, phone, name, email, avatarUrl).
- **OtpCode**: Temporary store for OTP verification.
- **Cashbook**: A ledger/book belonging to a User.
- **Record**: A transaction (income or expense) inside a Cashbook.

## Error Handling
The backend implements a global error handler that returns standardized JSON error responses:
```json
{
  "message": "Error description here",
  "stack": "..." // Only visible in development mode
}
```
Network/Validation errors will return appropriate HTTP status codes (400, 401, 403, 404, 500).
