import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../../../../apps/hello-world-frontend/src/environments/environment';

export interface GreetingResponse {
  message: string;
}

@Injectable({
  providedIn: 'root',
})
export class HelloApiService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/hello`;

  getGreeting(name: string): Observable<GreetingResponse> {
    return this.http.get<GreetingResponse>(this.apiUrl, {
      params: { name },
    });
  }
}
