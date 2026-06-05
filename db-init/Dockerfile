FROM mysql:8.0
COPY schema.sql /schema.sql
CMD ["sh", "-c", "mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < /schema.sql && echo 'Schema loaded'"]
