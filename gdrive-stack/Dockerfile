FROM alpine:3.21
RUN apk add --no-cache bash rclone restic yq ca-certificates tzdata
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh
ENTRYPOINT ["/scripts/entrypoint.sh"]
