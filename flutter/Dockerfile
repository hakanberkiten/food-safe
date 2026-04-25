FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY . .
RUN flutter pub get

# BACKEND_URL can be overridden at build time if needed.
ARG BACKEND_URL=http://127.0.0.1:8000
RUN flutter build web --release --dart-define=BACKEND_URL=${BACKEND_URL}

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
