import { Component, input, output, ViewChild, ElementRef, AfterViewInit, effect, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-todo-item',
  imports: [MatIconModule, MatButtonModule],
  templateUrl: './todo-item.html',
  styleUrl: './todo-item.css',
})
export class TodoItem implements AfterViewInit {
  id = input(0)
  name = input('');
  completed = input(false);
  editingItemId = input<number | null>(null);
  
  delete = output<number>();
  complete = output<number>();
  edit = output<{ id: number; name: string }>();
  editingChange = output<number | null>();

  isEditing = signal(false);
  editedName = signal('');

  @ViewChild('textarea') textarea?: ElementRef<HTMLTextAreaElement>;

  constructor() {
    effect(() => {
      this.name();
      setTimeout(() => this.adjustTextareaHeight(), 0);
    });
  }

  ngAfterViewInit() {
    this.adjustTextareaHeight();
  }

  adjustTextareaHeight() {
    if (this.textarea?.nativeElement) {
      const element = this.textarea.nativeElement;
      element.style.height = 'auto';
      element.style.height = element.scrollHeight + 'px';
    }
  }

  onEdit() {
    if (this.isEditing()) {
      this.editedName.set(this.name());
      this.isEditing.set(false);
      this.editingChange.emit(null);
    } else {
      this.editedName.set(this.name());
      this.isEditing.set(true);
      this.editingChange.emit(this.id());
      setTimeout(() => {
        if (this.textarea?.nativeElement) {
          this.textarea.nativeElement.focus();
        }
      }, 0);
    }
  }

  onTextChange(event: Event) {
    const target = event.target as HTMLTextAreaElement;
    this.editedName.set(target.value);
    this.adjustTextareaHeight();
  }

  onSave() {
    this.edit.emit({ id: this.id(), name: this.editedName() });
    this.isEditing.set(false);
  }

  onDelete() {
    this.delete.emit(this.id());
  }

  onComplete() {
    this.complete.emit(this.id());
  }
}
