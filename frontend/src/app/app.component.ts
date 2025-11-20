import { Component, ChangeDetectionStrategy } from '@angular/core';
import { HelloComponent } from './hello/hello.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [HelloComponent],
  template: '<app-hello></app-hello>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {}
