import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";
import { fileURLToPath } from 'url';
import path from 'path';

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

// Initialize routes and server
// Note: We removed top-level await to be compatible with Vercel Serverless Functions
const server = registerRoutes(app);

app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  const status = err.status || err.statusCode || 500;
  const message = err.message || "Internal Server Error";

  res.status(status).json({ message });
  throw err;
});

// Setup Vite or Static serving
if (app.get("env") === "development") {
  (async () => {
    await setupVite(app, server);
  })();
} else {
  // On Vercel, static files are served by the platform.
  // We attempt to serve them for other environments, but don't hard crash if missing.
  try {
    serveStatic(app);
  } catch (err) {
    // Only log if not on Vercel to avoid noise
    if (!process.env.VERCEL) {
      console.warn("Static assets not found, skipping static serving.");
    }
  }
}

// Serve on port if running directly
// This check allows the file to be imported (e.g. by Vercel) without starting the server
const isMainModule = process.argv[1] === fileURLToPath(import.meta.url);

if (isMainModule) {
  const port = parseInt(process.env.PORT || '5000', 10);

  server.listen(port, () => {
    log(`serving on port ${port}`);
  }).on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      log(`Port ${port} is already in use. Please try a different port.`);
    } else {
      log(`Server error: ${err.message}`);
    }
    process.exit(1);
  });
}

export default app;
