# PAWNDER BACKEND DEV GUIDE 


### 1. Prerequisites
Before you begin, ensure your Ccomputer has the following:
* **Docker Desktop**: Must be installed and running (Green whale icon in the tray).
* **PyCharm Professional**: (YOU CAN GET THE PRO VERSION FOR FREE WITH YOUR STUDENT EMAIL)

### 2. Initial Setup
1.  **Clone the Repository**: Use PyCharm to "Get from Version Control" via GitHub. (New Project > Get from Version Control > GitHub > Paste URL).
2.  **Create your Secrets**:
    * In the root directory, create a new file named exactly `.env`.
    * Copy the contents of `.env.example` into it.
    * Use the `POSTGRES_USER` and `POSTGRES_PASSWORD` I texted you personally.

### 3. The "One-Click" Launch
I made it simple for you all to run the entire project.
1.  Click **Add Configuration** (top-right corner).
2.  Select **Docker** > **Docker Compose**.
3.  Click the plus button in the top left of the little window, then choose the `docker-compose.yml` file.
4.  Name it whatever and click **OK**.
5.  Press the start button. The system will build your images and initialize the database roles automatically.

### 4. Verified Services
Once the containers are "Healthy" in your **Services** tab, you can access the following:

| Service | URL/Port | Description |
| :--- | :--- | :--- |
| **API Documentation** | `http://localhost:8000/docs` | Interactive Swagger UI for testing endpoints. |
| **PostGIS Database** | `localhost:5432` | Connect via PyCharm's **Database** tab using your `.env` credentials. |

### 5. Connecting the Database
1. On the very right, click on the database icon. Click **Add Data Source**
2. Select **PostgreSQL**
3. Enter the following:
    * **Server**: `localhost`
    * **Port**: `5432`
    * **User**: (from your `.env`)
    * **Password**: (from your `.env`)
    * **Database**: `pawnder_db`
4. Click **Test Connection** to ensure it works, then **OK**.

Done. The tables are already set up. No need to worry about schema changes.

---

### Dev Flow and best practices
* **Branching**: Never push directly to `main`. Create a feature branch: `feature/your-task-name`.
* **Pull Requests**: All code must be merged via a PR and approved by the someone.
* **Linting**: Run `ruff check .` before committing to ensure the code stays clean and professional.
* **Database Schema**: Do not attempt to `DROP` or `ALTER` tables. Schema changes must be approved and handled by the superuser account.

---

### Troubleshooting
* **Permission Denied**: Ensure you are using your assigned user and password in your `.env` file.
* **Port 5432 in use**: Make sure you have stopped any local (Windows native) PostgreSQL services before running Docker.