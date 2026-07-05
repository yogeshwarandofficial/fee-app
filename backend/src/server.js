require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const app = require('./app');
const connectDB = require('./config/db');

const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0'; // Listen on all interfaces so physical devices can connect

const startServer = async () => {
  try {
    // Connect to MongoDB first — refuse to accept traffic if DB is unavailable
    await connectDB();

    const server = app.listen(PORT, HOST, () => {
      console.log(`✅ Server running on ${HOST}:${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
      console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
    });

    // ── Keep-alive settings ────────────────────────────────────────────────
    // Increase keep-alive timeout to prevent mid-request connection resets,
    // especially important when Flutter app holds persistent connections.
    server.keepAliveTimeout = 65000;     // 65 s (must be > typical load balancer timeout)
    server.headersTimeout   = 66000;     // must be > keepAliveTimeout

    // ── Graceful shutdown ──────────────────────────────────────────────────
    const shutdown = (signal) => {
      console.log(`\n⚠️  Received ${signal}. Shutting down gracefully…`);
      server.close(() => {
        console.log('✅ HTTP server closed.');
        process.exit(0);
      });
      // Force-exit if graceful close takes too long
      setTimeout(() => {
        console.error('❌ Forced shutdown after timeout.');
        process.exit(1);
      }, 10_000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT',  () => shutdown('SIGINT'));

    // ── Unhandled rejection guard ──────────────────────────────────────────
    process.on('unhandledRejection', (reason) => {
      console.error('❌ Unhandled Promise Rejection:', reason);
      // Do NOT exit — just log. Exiting on every rejection is too aggressive.
    });

  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
