const http = require("http");
const { Pool } = require("pg");

const port = 1337;

const pool = new Pool({
  host: "localhost",
  database: "development"
});

const server = http
  .createServer((req, res) => {
    pool.connect((err, db, release) => {
      try {
        if (err) {
          return res.status(500).send(err.toString());
        }

        let body = "";

        req.on("data", chunk => {
          body += chunk;
        });
        req.on("end", () => {
          db.query(
            `
            select status, body, to_json(headers) as headers from app.main(
              http.request(
                method := $1,
                path := $2,
                body := $3
              )
            )`,
            [req.method, req.url, body],
            (err, result) => {
              if (err) {
                return res.writeHead(500).end(err.toString());
              }
              const {
                rows: [{ status, body, headers }]
              } = result;

              const objHeaders = Object.fromEntries(
                headers.map(({ name, value }) => [name, value])
              );
              return res.writeHead(status, objHeaders).end(body);
            }
          );
        });
        req.read();
      } finally {
        release();
      }
    });
  })
  .listen(port);
