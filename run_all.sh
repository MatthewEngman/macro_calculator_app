#!/bin/bash

echo "Launching FastAPI backend..."
cd backend
uvicorn main:app --reload &
cd ..

# echo "Launching Flutter app..."
# flutter run - Add this back when flutter app is ready

chmod +x run_all.sh
