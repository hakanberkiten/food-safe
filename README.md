## Food Safe Backend

Food Safe is a FastAPI-based backend for a mobile application that helps users identify allergens and unsafe ingredients in food products.

### Features

- **User Authentication**: Secure signup and login with JWT-based authentication.
- **Scan History**: Users can view their past food scans.
- **Saved Products**: Users can save products to a "safe list" for quick reference.
- **Profile Management**: Users can manage their allergies, conditions, and special dietary needs.
- **AI Analysis**: Integrates with Google Gemini to analyze food ingredients and assess risk levels.

### Tech Stack

- **Framework**: FastAPI
- **Database**: SQLAlchemy (SQLite for development)
- **Authentication**: JWT (JSON Web Tokens)
- **AI**: Google Gemini
- **Security**: Passlib (bcrypt) for password hashing

### Setup

1.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

2.  **Environment Variables**:
    Create a `.env` file in the `backend` directory with the following variables:
    ```env
    GEMINI_API_KEY=your_gemini_api_key
    DATABASE_URL=sqlite:///./food_safe.db
    SECRET_KEY=your_secret_key
    ```

3.  **Database Initialization**:
    Run the following command to create the database tables:
    ```bash
    python -c "from app.core.database import init_db; init_db()"
    ```

4.  **Run the Server**:
    ```bash
    uvicorn app.main:app --reload
    ```
    The API will be available at `http://localhost:8000`.

### API Documentation

Interactive API documentation is available at `http://localhost:8000/docs`.