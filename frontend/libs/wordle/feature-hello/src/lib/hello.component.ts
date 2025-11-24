import { Component, ChangeDetectionStrategy, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HelloApiService, GreetingResponse } from '@wordle-kata/data-access';
import { LoggerService } from '@wordle-kata/util-logging';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { CardModule } from 'primeng/card';
import { MessageModule } from 'primeng/message';
import { FloatLabelModule } from 'primeng/floatlabel';

@Component({
  selector: 'app-hello',
  imports: [
    FormsModule,
    ButtonModule,
    InputTextModule,
    CardModule,
    MessageModule,
    FloatLabelModule,
  ],
  templateUrl: './hello.component.html',
  styleUrl: './hello.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HelloComponent {
  private readonly helloApiService = inject(HelloApiService);
  private readonly logger = inject(LoggerService);

  readonly name = signal<string>('World');
  readonly greeting = signal<string | null>(null);
  readonly loading = signal<boolean>(false);
  readonly error = signal<string | null>(null);

  fetchGreeting(): void {
    this.loading.set(true);
    this.error.set(null);

    this.helloApiService.getGreeting(this.name()).subscribe({
      next: (response: GreetingResponse) => {
        this.greeting.set(response.message);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to fetch greeting. Make sure the backend is running.');
        this.loading.set(false);
        this.logger.error('Error fetching greeting:', err);
      },
    });
  }

  updateName(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.name.set(input.value);
  }
}
