import { HelloComponent } from './hello.component';
import { HelloApiService, GreetingResponse } from './hello-api.service';
import { of, throwError, delay } from 'rxjs';

interface MockHelloApiService {
  getGreeting: Cypress.Agent<sinon.SinonStub>;
}

describe('HelloComponent', () => {
  let mockHelloApiService: MockHelloApiService;

  beforeEach(() => {
    mockHelloApiService = {
      getGreeting: cy.stub().as('getGreeting'),
    };
  });

  it('should mount the component', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    });

    cy.contains('h1', 'Hello World Demo').should('be.visible');
  });

  it('should display default name in input field', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    });

    cy.get('#nameInput').should('have.value', 'World');
  });

  it('should update name when input changes', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    });

    // Arrange & Act
    cy.get('#nameInput').clear().type('Alice');

    // Assert - signal value is updated (we can verify through component behavior)
    cy.get('#nameInput').should('have.value', 'Alice');
  });

  it('should fetch greeting successfully when button clicked', () => {
    const mockResponse: GreetingResponse = {
      message: 'Hello, Alice! Welcome to the world.',
    };

    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    }).then(({ component }) => {
      // Arrange
      mockHelloApiService.getGreeting.returns(of(mockResponse));
      component.name.set('Alice');
      cy.wrap(component).as('component');
    });

    // Act
    cy.get('button').contains('Get Greeting').click();

    // Assert
    cy.get('@getGreeting').should('have.been.calledWith', 'Alice');
    cy.get('.greeting-result h2').should('contain', 'Hello, Alice! Welcome to the world.');
  });

  it('should display error when API call fails', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    }).then(() => {
      // Arrange
      mockHelloApiService.getGreeting.returns(throwError(() => new Error('Network error')));
    });

    // Act
    cy.get('button').contains('Get Greeting').click();

    // Assert
    cy.get('.error-message').should('contain', 'Failed to fetch greeting');
  });

  it('should show loading state during API call', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    }).then(() => {
      // Arrange - create a delayed observable
      const mockResponse: GreetingResponse = {
        message: 'Hello, World! Welcome to the world.',
      };
      mockHelloApiService.getGreeting.returns(of(mockResponse).pipe(delay(100)));
    });

    // Act
    cy.get('button').contains('Get Greeting').click();

    // Assert - button should show loading text
    cy.get('button').should('contain', 'Loading...');
    cy.get('button').should('be.disabled');
  });

  it('should clear error when making new request', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: mockHelloApiService }],
    }).then(({ component }) => {
      // Arrange - first call fails
      mockHelloApiService.getGreeting
        .onFirstCall()
        .returns(throwError(() => new Error('Network error')));
      component.fetchGreeting();
    });

    // Verify error is shown
    cy.get('.error-message').should('be.visible');

    // Arrange - second call succeeds
    cy.then(() => {
      mockHelloApiService.getGreeting.returns(
        of({ message: 'Hello, World! Welcome to the world.' })
      );
    });

    // Act - make new request
    cy.get('button').contains('Get Greeting').click();

    // Assert - error should be cleared
    cy.get('.error-message').should('not.exist');
    cy.get('.greeting-result').should('be.visible');
  });
});
