import { TestBed } from '@angular/core/testing';
import { LoggerService, LogLevel } from './logger.service';

describe('LoggerService', () => {
  let service: LoggerService;
  let consoleDebugSpy: Cypress.Agent<sinon.SinonSpy>;
  let consoleInfoSpy: Cypress.Agent<sinon.SinonSpy>;
  let consoleWarnSpy: Cypress.Agent<sinon.SinonSpy>;
  let consoleErrorSpy: Cypress.Agent<sinon.SinonSpy>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [LoggerService],
    });

    service = TestBed.inject(LoggerService);

    // Spy on console methods
    consoleDebugSpy = cy.spy(console, 'debug');
    consoleInfoSpy = cy.spy(console, 'info');
    consoleWarnSpy = cy.spy(console, 'warn');
    consoleErrorSpy = cy.spy(console, 'error');
  });

  it('should be created', () => {
    expect(service).to.exist;
  });

  describe('debug()', () => {
    it('should log debug message when log level is Debug', () => {
      // Arrange
      service.setLogLevel(LogLevel.Debug);

      // Act
      service.debug('Debug message', 'arg1', 'arg2');

      // Assert
      expect(consoleDebugSpy).to.have.been.calledWith('[DEBUG] Debug message', 'arg1', 'arg2');
    });

    it('should not log debug message when log level is Info', () => {
      // Arrange
      service.setLogLevel(LogLevel.Info);

      // Act
      service.debug('Debug message');

      // Assert
      expect(consoleDebugSpy).not.to.have.been.called;
    });

    it('should not log debug message when log level is Warn', () => {
      // Arrange
      service.setLogLevel(LogLevel.Warn);

      // Act
      service.debug('Debug message');

      // Assert
      expect(consoleDebugSpy).not.to.have.been.called;
    });

    it('should not log debug message when log level is Error', () => {
      // Arrange
      service.setLogLevel(LogLevel.Error);

      // Act
      service.debug('Debug message');

      // Assert
      expect(consoleDebugSpy).not.to.have.been.called;
    });
  });

  describe('info()', () => {
    it('should log info message when log level is Debug', () => {
      // Arrange
      service.setLogLevel(LogLevel.Debug);

      // Act
      service.info('Info message', 'arg1');

      // Assert
      expect(consoleInfoSpy).to.have.been.calledWith('[INFO] Info message', 'arg1');
    });

    it('should log info message when log level is Info', () => {
      // Arrange
      service.setLogLevel(LogLevel.Info);

      // Act
      service.info('Info message');

      // Assert
      expect(consoleInfoSpy).to.have.been.calledWith('[INFO] Info message');
    });

    it('should not log info message when log level is Warn', () => {
      // Arrange
      service.setLogLevel(LogLevel.Warn);

      // Act
      service.info('Info message');

      // Assert
      expect(consoleInfoSpy).not.to.have.been.called;
    });

    it('should not log info message when log level is Error', () => {
      // Arrange
      service.setLogLevel(LogLevel.Error);

      // Act
      service.info('Info message');

      // Assert
      expect(consoleInfoSpy).not.to.have.been.called;
    });
  });

  describe('warn()', () => {
    it('should log warn message when log level is Debug', () => {
      // Arrange
      service.setLogLevel(LogLevel.Debug);

      // Act
      service.warn('Warning message', { key: 'value' });

      // Assert
      expect(consoleWarnSpy).to.have.been.calledWith('[WARN] Warning message', { key: 'value' });
    });

    it('should log warn message when log level is Info', () => {
      // Arrange
      service.setLogLevel(LogLevel.Info);

      // Act
      service.warn('Warning message');

      // Assert
      expect(consoleWarnSpy).to.have.been.calledWith('[WARN] Warning message');
    });

    it('should log warn message when log level is Warn', () => {
      // Arrange
      service.setLogLevel(LogLevel.Warn);

      // Act
      service.warn('Warning message');

      // Assert
      expect(consoleWarnSpy).to.have.been.calledWith('[WARN] Warning message');
    });

    it('should not log warn message when log level is Error', () => {
      // Arrange
      service.setLogLevel(LogLevel.Error);

      // Act
      service.warn('Warning message');

      // Assert
      expect(consoleWarnSpy).not.to.have.been.called;
    });
  });

  describe('error()', () => {
    it('should log error message when log level is Debug', () => {
      // Arrange
      service.setLogLevel(LogLevel.Debug);

      // Act
      service.error('Error message', new Error('test error'));

      // Assert
      expect(consoleErrorSpy).to.have.been.calledWith(
        '[ERROR] Error message',
        Cypress.sinon.match.instanceOf(Error)
      );
    });

    it('should log error message when log level is Info', () => {
      // Arrange
      service.setLogLevel(LogLevel.Info);

      // Act
      service.error('Error message');

      // Assert
      expect(consoleErrorSpy).to.have.been.calledWith('[ERROR] Error message');
    });

    it('should log error message when log level is Warn', () => {
      // Arrange
      service.setLogLevel(LogLevel.Warn);

      // Act
      service.error('Error message');

      // Assert
      expect(consoleErrorSpy).to.have.been.calledWith('[ERROR] Error message');
    });

    it('should log error message when log level is Error', () => {
      // Arrange
      service.setLogLevel(LogLevel.Error);

      // Act
      service.error('Error message');

      // Assert
      expect(consoleErrorSpy).to.have.been.calledWith('[ERROR] Error message');
    });
  });

  describe('setLogLevel()', () => {
    it('should filter logs based on log level hierarchy', () => {
      // Arrange
      service.setLogLevel(LogLevel.Warn);

      // Act
      service.debug('Debug message');
      service.info('Info message');
      service.warn('Warn message');
      service.error('Error message');

      // Assert
      expect(consoleDebugSpy).not.to.have.been.called;
      expect(consoleInfoSpy).not.to.have.been.called;
      expect(consoleWarnSpy).to.have.been.calledOnce;
      expect(consoleErrorSpy).to.have.been.calledOnce;
    });

    it('should allow all logs when log level is Debug', () => {
      // Arrange
      service.setLogLevel(LogLevel.Debug);

      // Act
      service.debug('Debug message');
      service.info('Info message');
      service.warn('Warn message');
      service.error('Error message');

      // Assert
      expect(consoleDebugSpy).to.have.been.calledOnce;
      expect(consoleInfoSpy).to.have.been.calledOnce;
      expect(consoleWarnSpy).to.have.been.calledOnce;
      expect(consoleErrorSpy).to.have.been.calledOnce;
    });

    it('should only allow error logs when log level is Error', () => {
      // Arrange
      service.setLogLevel(LogLevel.Error);

      // Act
      service.debug('Debug message');
      service.info('Info message');
      service.warn('Warn message');
      service.error('Error message');

      // Assert
      expect(consoleDebugSpy).not.to.have.been.called;
      expect(consoleInfoSpy).not.to.have.been.called;
      expect(consoleWarnSpy).not.to.have.been.called;
      expect(consoleErrorSpy).to.have.been.calledOnce;
    });
  });
});
