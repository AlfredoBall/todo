import { Component, input, output, signal, effect, ViewChild, ElementRef } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-clipboard-item',
  imports: [MatIconModule, MatButtonModule],
  templateUrl: './clipboard-item.html',
  styleUrl: './clipboard-item.css'
})
export class ClipboardItem {
  id = input(0);
  name = input('');
  isSelected = input(false);
  editingClipboardId = input<number | null>(null);
  
  select = output<number>();
  delete = output<number>();
  edit = output<{ id: number; name: string }>();
  editingChange = output<number | null>();
  nameChange = output<string>();

  isEditing = signal(false);
  editedName = signal('');

  @ViewChild('nameInput') nameInput?: ElementRef<HTMLInputElement>;

  constructor() {
    effect(() => {
      const editingId = this.editingClipboardId();
      if (editingId !== this.id() && this.isEditing()) {
        this.isEditing.set(false);
      }
    });
  }

  onEdit() {
    if (this.isEditing()) {
      // Revert/cancel
      this.editedName.set(this.name());
      this.isEditing.set(false);
      this.editingChange.emit(null);
      if (this.nameInput) {
        this.nameInput.nativeElement.readOnly = true;
      }
    } else {
      // Start editing
      this.editedName.set(this.name());
      this.isEditing.set(true);
      this.editingChange.emit(this.id());
      setTimeout(() => {
        if (this.nameInput) {
          this.nameInput.nativeElement.readOnly = false;
          this.nameInput.nativeElement.focus();
        }
      }, 0);
    }
  }

  onNameChange(event: Event) {
    const target = event.target as HTMLInputElement;
    const value = target.value;
    this.editedName.set(value);
    this.nameChange.emit(value);
  }

  onSave() {
    if (this.editedName().trim() && this.editedName() !== this.name()) {
      this.edit.emit({ id: this.id(), name: this.editedName() });
    }
    this.isEditing.set(false);
    this.editingChange.emit(null);
    if (this.nameInput) {
      this.nameInput.nativeElement.readOnly = true;
    }
  }

  onCancel() {
    this.editedName.set(this.name());
    this.isEditing.set(false);
    this.editingChange.emit(null);
    if (this.nameInput) {
      this.nameInput.nativeElement.readOnly = true;
    }
  }

  onDelete() {
    this.delete.emit(this.id());
  }

  onSelect() {
    if (!this.isEditing()) {
      this.select.emit(this.id());
    }
  }
}
