import { HelloComponent } from './hello.component';
import { HelloApiService, GreetingResponse } from '@wordle-kata/data-access';
import { of, throwError, delay } from 'rxjs';
import { provideAnimations } from '@angular/platform-browser/animations';

interface StubHelloApiService {
  getGreeting: Cypress.Agent<sinon.SinonStub>;
}

describe('HelloComponent', () => {
  let stubHelloApiService: StubHelloApiService;

  beforeEach(() => {
    stubHelloApiService = {
      getGreeting: cy.stub().as('getGreeting'),
    };
  });

  it('should mount the component', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    });

    cy.contains('Hello World Demo').should('be.visible');
  });

  it('should display default name in input field', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    });

    cy.get('#nameInput').should('have.value', 'World');
  });

  it('should update name when input changes', () => {
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    });

    // Arrange & Act
    cy.get('#nameInput').clear().type('Alice');

    // Assert - signal value is updated (we can verify through component behavior)
    cy.get('#nameInput').should('have.value', 'Alice');
  });

  it('should fetch greeting successfully when button clicked', () => {
    // NOTE: This test uses the stub as a MOCK - verifies interaction happened
    const mockResponse: GreetingResponse = {
      message: 'Hello, Alice! Welcome to the world.',
    };

    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    }).then(({ component }) => {
      // Arrange
      stubHelloApiService.getGreeting.returns(of(mockResponse));
      component.name.set('Alice');
      cy.wrap(component).as('component');
    });

    // Act
    cy.get('button').click();

    // Assert - Behavior verification (MOCK usage)
    cy.get('@getGreeting').should('have.been.calledWith', 'Alice');
    // Assert - State verification
    cy.get('.greeting-result h2').should('contain', 'Hello, Alice! Welcome to the world.');
  });

  it('should display error when API call fails', () => {
    // NOTE: STUB usage - provides error response, no verification
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    }).then(() => {
      // Arrange - Stub returns error
      stubHelloApiService.getGreeting.returns(throwError(() => new Error('Network error')));
    });

    // Act
    cy.get('button').click();

    // Assert - State verification only
    cy.get('p-message').should('contain', 'Failed to fetch greeting');
  });

  it('should show loading state during API call', () => {
    // NOTE: STUB usage - provides delayed response, no verification
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    }).then(() => {
      // Arrange - Stub returns delayed observable
      const mockResponse: GreetingResponse = {
        message: 'Hello, World! Welcome to the world.',
      };
      stubHelloApiService.getGreeting.returns(of(mockResponse).pipe(delay(100)));
    });

    // Act
    cy.get('button').click();

    // Assert - State verification only
    cy.get('button .p-button-loading-icon').should('exist');
    cy.get('button').should('be.disabled');
  });

  it('should clear error when making new request', () => {
    // NOTE: STUB usage - provides different responses, no verification
    cy.mount(HelloComponent, {
      providers: [{ provide: HelloApiService, useValue: stubHelloApiService }, provideAnimations()],
    }).then(({ component }) => {
      // Arrange - Stub returns error on first call
      stubHelloApiService.getGreeting
        .onFirstCall()
        .returns(throwError(() => new Error('Network error')));
      component.fetchGreeting();
    });

    // Verify error is shown
    cy.get('p-message').should('be.visible');

    // Arrange - Stub returns success on subsequent calls
    cy.then(() => {
      stubHelloApiService.getGreeting.returns(
        of({ message: 'Hello, World! Welcome to the world.' })
      );
    });

    // Act - make new request
    cy.get('button').click();

    // Assert - State verification only
    cy.get('p-message').should('not.exist');
    cy.get('.greeting-result').should('be.visible');
  });
});
