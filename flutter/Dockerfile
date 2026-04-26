FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY . .
RUN flutter pub get

ARG BACKEND_URL=https://backend-production-cdeb7.up.railway.app
RUN flutter build web --release --dart-define=BACKEND_URL=${BACKEND_URL}

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
