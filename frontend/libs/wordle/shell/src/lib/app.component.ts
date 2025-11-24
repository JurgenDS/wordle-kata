import { Component, ChangeDetectionStrategy } from '@angular/core';
import { HelloComponent } from '@wordle-kata/feature-hello';

@Component({
  selector: 'app-root',
  imports: [HelloComponent],
  template: '<app-hello></app-hello>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {}
