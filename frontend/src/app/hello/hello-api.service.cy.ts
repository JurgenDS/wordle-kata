import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { HelloApiService, GreetingResponse } from './hello-api.service';

describe('HelloApiService', () => {
  let service: HelloApiService;
  let fakeHttpBackend: HttpTestingController; // FAKE: Working HTTP implementation without real network calls

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), HelloApiService],
    });

    service = TestBed.inject(HelloApiService);
    fakeHttpBackend = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    fakeHttpBackend.verify();
  });

  it('should be created', () => {
    expect(service).to.be.instanceOf(HelloApiService);
  });

  it('should fetch greeting with custom name', (done) => {
    // Arrange
    const name = 'Alice';
    const stubResponse: GreetingResponse = {
      message: 'Hello, Alice! Welcome to the world.',
    };

    // Act
    service.getGreeting(name).subscribe((response) => {
      // Assert
      expect(response).to.deep.equal(stubResponse);
      expect(response.message).to.include('Alice');
      done();
    });

    // Fake HTTP backend intercepts and responds
    const req = fakeHttpBackend.expectOne('http://localhost:8080/api/hello?name=Alice');
    expect(req.request.method).to.equal('GET');
    req.flush(stubResponse);
  });

  it('should fetch greeting with default name', (done) => {
    // Arrange
    const name = 'World';
    const stubResponse: GreetingResponse = {
      message: 'Hello, World! Welcome to the world.',
    };

    // Act
    service.getGreeting(name).subscribe((response) => {
      // Assert
      expect(response).to.deep.equal(stubResponse);
      done();
    });

    // Fake HTTP backend intercepts and responds
    const req = fakeHttpBackend.expectOne('http://localhost:8080/api/hello?name=World');
    expect(req.request.method).to.equal('GET');
    req.flush(stubResponse);
  });
});
