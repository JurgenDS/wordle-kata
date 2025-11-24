import { Injectable } from '@angular/core';

export enum LogLevel {
  Debug = 0,
  Info = 1,
  Warn = 2,
  Error = 3,
}

@Injectable({
  providedIn: 'root',
})
export class LoggerService {
  private logLevel: LogLevel = LogLevel.Info;

  setLogLevel(level: LogLevel): void {
    this.logLevel = level;
  }

  debug(message: string, ...args: unknown[]): void {
    if (this.logLevel <= LogLevel.Debug) {
      console.debug(`[DEBUG] ${message}`, ...args);
    }
  }

  info(message: string, ...args: unknown[]): void {
    if (this.logLevel <= LogLevel.Info) {
      console.info(`[INFO] ${message}`, ...args);
    }
  }

  warn(message: string, ...args: unknown[]): void {
    if (this.logLevel <= LogLevel.Warn) {
      console.warn(`[WARN] ${message}`, ...args);
    }
  }

  error(message: string, ...args: unknown[]): void {
    if (this.logLevel <= LogLevel.Error) {
      console.error(`[ERROR] ${message}`, ...args);
    }
  }
}
