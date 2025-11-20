import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { HelloApiService, GreetingResponse } from './hello-api.service';

describe('HelloApiService', () => {
  let service: HelloApiService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), HelloApiService],
    });

    service = TestBed.inject(HelloApiService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).to.be.instanceOf(HelloApiService);
  });

  it('should fetch greeting with custom name', (done) => {
    // Arrange
    const name = 'Alice';
    const mockResponse: GreetingResponse = {
      message: 'Hello, Alice! Welcome to the world.',
    };

    // Act
    service.getGreeting(name).subscribe((response) => {
      // Assert
      expect(response).to.deep.equal(mockResponse);
      expect(response.message).to.include('Alice');
      done();
    });

    // Assert - HTTP request
    const req = httpMock.expectOne('http://localhost:8080/api/hello?name=Alice');
    expect(req.request.method).to.equal('GET');
    req.flush(mockResponse);
  });

  it('should fetch greeting with default name', (done) => {
    // Arrange
    const name = 'World';
    const mockResponse: GreetingResponse = {
      message: 'Hello, World! Welcome to the world.',
    };

    // Act
    service.getGreeting(name).subscribe((response) => {
      // Assert
      expect(response).to.deep.equal(mockResponse);
      done();
    });

    // Assert - HTTP request
    const req = httpMock.expectOne('http://localhost:8080/api/hello?name=World');
    expect(req.request.method).to.equal('GET');
    req.flush(mockResponse);
  });
});
