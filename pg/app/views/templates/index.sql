begin;

  create schema if not exists templates;

  create or replace function templates.main(
    content xml,
    title text default 'Postgres App Server Example'
  ) returns xml as $$
    select xmlparse (content '
      <html>
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <link rel="stylesheet" href="https://fonts.xz.style/serve/inter.css" />
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@exampledev/new.css@1.1.2/new.min.css" />
          <script src="https://cdn.jsdelivr.net/gh/postlight/trimmings@d5e4b12/dist/trimmings.js"></script>
          <title>' || title || '</title>
        </head>
        <body>'|| content ||'</body>
      </html>
    ');
  $$ language sql immutable security invoker;

commit;
