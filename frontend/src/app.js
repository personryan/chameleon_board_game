import { createAppController } from './controllers/appController.js';
import { getSupabaseEnv } from './config/env.js';

const app = document.querySelector('#app');

try {
  getSupabaseEnv();
  createAppController(app).start();
} catch (error) {
  createAppController(app).start(error instanceof Error ? error.message : 'Could not start the app.');
}
