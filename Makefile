.PHONY: backend backend-local test flutter-run

backend:
	docker compose up --build -d

backend-local:
	.venv/bin/uvicorn app.main:app --app-dir backend --reload

test:
	flutter analyze
	flutter test
	PYTHONPATH=backend .venv/bin/pytest backend/tests -q

flutter-run:
	flutter run
