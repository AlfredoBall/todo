import { Component, inject, signal, ChangeDetectionStrategy, OnInit, OnDestroy, computed } from '@angular/core';
import { TodoItem } from '../../components/todo-item/todo-item';
import { ClipboardItem } from '../../components/clipboard-item/clipboard-item';
import { DataSource } from '../../services/data-source';
import { CommonModule } from '@angular/common';
import { form, Field, required } from '@angular/forms/signals';
import { Snackbar } from '../../services/snackbar';
import { HttpErrorResponse } from '@angular/common/http';
import { Router, ActivatedRoute } from '@angular/router';
import { Paging } from '../../components/paging/paging';

interface NewTodoItemData {
  name: string;
}

interface NewClipboardData {
  name: string;
}

@Component({
  selector: 'app-home',
  imports: [TodoItem, ClipboardItem, Paging, CommonModule, Field],
  templateUrl: './home.html',
  styleUrl: './home.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class Home implements OnInit, OnDestroy {

  // ========================================
  // Dependencies
  // ========================================
  private snackbar = inject(Snackbar);
  private dataSource = inject(DataSource);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private routeSubscription?: any;
  private queryParamsSubscription?: any;

  // ========================================
  // Shared State
  // ========================================
  selectedClipboardId = signal<number | null>(null);
  filter = signal<'all' | 'completed' | 'unfinished'>('all');
  currentPage = signal<number>(1);
  itemsPerPage = 10;

  // ========================================
  // Todo Items State & Computed
  // ========================================
  items$ = signal<any[]>([]);
  editingItemId = signal<number | null>(null);

  newTodoItemModel = signal<NewTodoItemData>({
      name: '',
  });

  newTodoItemForm = form(this.newTodoItemModel, (schemaPath) => {
    required(schemaPath.name, { message: 'Name is required and cannot be only whitespace' });
  });

  filteredItems = computed(() => {
    const items = this.items$();
    const filterValue = this.filter();
    
    if (filterValue === 'completed') {
      return items.filter(item => item.isComplete);
    } else if (filterValue === 'unfinished') {
      return items.filter(item => !item.isComplete);
    }
    return items;
  });

  pagedItems = computed(() => {
    const filtered = this.filteredItems();
    const page = this.currentPage();
    const startIndex = (page - 1) * this.itemsPerPage;
    const endIndex = startIndex + this.itemsPerPage;
    return filtered.slice(startIndex, endIndex);
  });

  totalPages = computed(() => {
    return Math.ceil(this.filteredItems().length / this.itemsPerPage);
  });

  allItemsCount = computed(() => this.items$().length);
  
  completedItemsCount = computed(() => 
    this.items$().filter(item => item.isComplete).length
  );
  
  unfinishedItemsCount = computed(() => 
    this.items$().filter(item => !item.isComplete).length
  );

  // ========================================
  // Clipboard State & Computed
  // ========================================
  clipboards$ = signal<any[]>([]);
  editingClipboardId = signal<number | null>(null);
  editedClipboardName = signal<string>('');

  hasClipboards = computed(() => this.clipboards$().length > 0);

  newClipboardModel = signal<NewClipboardData>({
      name: '',
  });

  newClipboardForm = form(this.newClipboardModel, (schemaPath) => {
    required(schemaPath.name, { 
      message: 'Clipboard name is required and cannot be only whitespace'
    });
  });

  clipboardNameChanged = computed(() => {
    const editingId = this.editingClipboardId();
    if (editingId === null) return false;
    const clipboard = this.clipboards$().find(c => c.id === editingId);
    if (!clipboard) return false;
    return this.editedClipboardName() !== clipboard.name;
  });

  // ========================================
  // Lifecycle Hooks
  // ========================================
  ngOnInit() {
    this.queryParamsSubscription = this.route.queryParams.subscribe(params => {
      const filterParam = params['filter'];
      if (filterParam === 'completed' || filterParam === 'unfinished') {
        this.filter.set(filterParam);
      } else {
        this.filter.set('all');
      }

      const pageParam = params['page'];
      const page = pageParam ? Number(pageParam) : 1;
      this.currentPage.set(page > 0 ? page : 1);
    });
    
    this.routeSubscription = this.route.paramMap.subscribe(params => {
      const urlClipboardId = params.get('clipboardId');
      
      this.dataSource.fetchClipboards().subscribe(clipboards => {
        this.clipboards$.set(clipboards);
        this.handleClipboardRoute(urlClipboardId, clipboards);
      });
    });
  }

  ngOnDestroy() {
    this.routeSubscription?.unsubscribe();
    this.queryParamsSubscription?.unsubscribe();
  }

  // ========================================
  // Routing & Navigation
  // ========================================
  private handleClipboardRoute(urlClipboardId: string | null, clipboards: any[]) {
    if (urlClipboardId) {
      const clipboardId = Number(urlClipboardId);
      
      if (clipboards.some(c => c.id === clipboardId)) {
        this.selectedClipboardId.set(clipboardId);
        this.loadItemsForClipboard(clipboardId);
      } else if (clipboards.length > 0) {
        const currentFilter = this.filter();
        const page = this.currentPage();
        const queryParams: any = {};
        if (currentFilter !== 'all') queryParams.filter = currentFilter;
        if (page > 1) queryParams.page = page;
        this.router.navigate(['/clipboard', clipboards[0].id], { replaceUrl: true, queryParams });
      }
    } else if (clipboards.length > 0) {
      const currentFilter = this.filter();
      const page = this.currentPage();
      const queryParams: any = {};
      if (currentFilter !== 'all') queryParams.filter = currentFilter;
      if (page > 1) queryParams.page = page;
      this.router.navigate(['/clipboard', clipboards[0].id], { replaceUrl: true, queryParams });
    }
  }

  selectClipboard(clipboardId: number) {
    this.selectedClipboardId.set(clipboardId);
    
    const currentFilter = this.filter();
    const page = this.currentPage();
    const queryParams: any = {};
    if (currentFilter !== 'all') queryParams.filter = currentFilter;
    if (page > 1) queryParams.page = page;
    
    this.router.navigate(['/clipboard', clipboardId], { 
      queryParams
    });
    this.loadItemsForClipboard(clipboardId);
  }

  setFilter(filter: 'all' | 'completed' | 'unfinished') {
    this.filter.set(filter);
    this.currentPage.set(1);
    const clipboardId = this.selectedClipboardId();
    if (clipboardId) {
      const queryParams: any = {};
      if (filter !== 'all') queryParams.filter = filter;
      this.router.navigate(['/clipboard', clipboardId], { 
        queryParams
      });
    }
  }

  setPage(page: number) {
    this.currentPage.set(page);
    const clipboardId = this.selectedClipboardId();
    if (clipboardId) {
      const currentFilter = this.filter();
      const queryParams: any = {};
      if (currentFilter !== 'all') queryParams.filter = currentFilter;
      if (page > 1) queryParams.page = page;
      this.router.navigate(['/clipboard', clipboardId], { 
        queryParams
      });
    }
  }

  private adjustPageIfNeeded() {
    const currentPage = this.currentPage();
    const totalPages = this.totalPages();
    
    if (currentPage > totalPages && totalPages > 0) {
      this.setPage(totalPages);
    } else if (currentPage > 1 && this.pagedItems().length === 0 && this.filteredItems().length > 0) {
      this.setPage(Math.max(1, totalPages));
    }
  }

  // ========================================
  // Todo Items - Data Loading
  // ========================================
  loadItemsForClipboard(clipboardId: number) {
    this.dataSource.fetchItems(clipboardId).subscribe(items => {
      this.items$.set(items);
    });
  }

  // ========================================
  // Todo Items - Event Handlers
  // ========================================
  onAddTodoItem(event: Event) {
    event.preventDefault();
    const newTodoItem = this.newTodoItemModel();
    
    const clipboardId = this.selectedClipboardId();
    if (!clipboardId) {
      this.snackbar.openSnackBar('Please select a clipboard first', 'Close', true);
      return;
    }

    if (this.newTodoItemForm.name().invalid()) {
      this.newTodoItemForm.name().markAsTouched();
      return;
    }

    // Validate that the trimmed name is not empty
    if (newTodoItem.name.trim().length === 0) {
      this.snackbar.openSnackBar('Todo item name cannot be only whitespace', 'Close', true);
      return;
    }

    this.dataSource.addItem(clipboardId, newTodoItem.name).subscribe({
      next: (response) => {
        this.snackbar.openSnackBar('Item added successfully', 'Close');
        this.items$.set([...this.items$(), response]);
        this.resetTodoItemForm();
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error adding item', 'Close', true);
        console.error('Error submitting data:', error);
        if (error.status === 400) {
          console.error('Invalid Request.');
        } else if (error.status === 500) {
          console.error('Server error.');
        } else {
          console.error('An unexpected error occurred.');
        }
      }
    });
  }

  onDeleteTodoItem(id: number) {
    this.dataSource.removeItem(id).subscribe({
      next: () => {
        this.snackbar.openSnackBar('Item deleted successfully', 'Close');
        this.items$.set(this.items$().filter(item => item.id !== id));
        this.adjustPageIfNeeded();
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error deleting item', 'Close', true);
        console.error('Error deleting item:', error);
      }
    });
  }

  onCompleteTodoItem(id: number) {
    const item = this.items$().find(i => i.id === id);
    if (!item) return;

    const apiCall = item.isComplete 
      ? this.dataSource.unfinishItem(id) 
      : this.dataSource.completeItem(id);

    apiCall.subscribe({
      next: () => {
        this.snackbar.openSnackBar(
          item.isComplete ? 'Item marked as incomplete' : 'Item completed', 
          'Close'
        );
        this.items$.set(
          this.items$().map(i => 
            i.id === id ? { ...i, isComplete: !i.isComplete } : i
          )
        );
        this.adjustPageIfNeeded();
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error updating item', 'Close', true);
        console.error('Error updating item:', error);
      }
    });
  }

  onEditTodoItem(event: { id: number; name: string }) {
    if (event.name.trim().length === 0) {
      this.snackbar.openSnackBar('Todo item name cannot be only whitespace', 'Close', true);
      this.editingItemId.set(null);
      return;
    }

    this.dataSource.editItem(event.id, event.name).subscribe({
      next: () => {
        this.snackbar.openSnackBar('Item updated successfully', 'Close');
        this.items$.set(
          this.items$().map(i => 
            i.id === event.id ? { ...i, name: event.name } : i
          )
        );
        this.editingItemId.set(null);
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error updating item', 'Close', true);
        console.error('Error editing item:', error);
      }
    });
  }

  onEditingTodoItemChange(id: number | null) {
    this.editingItemId.set(id);
  }

  resetTodoItemForm() : void {
    this.newTodoItemModel.set({
      name: ' ',
    });

    this.newTodoItemForm.name().markAsDirty()
  }

  // ========================================
  // Clipboard - Event Handlers
  // ========================================
  onClipboardChange(event: Event) {
    const selectElement = event.target as HTMLSelectElement;
    const clipboardId = Number(selectElement.value);
    this.selectClipboard(clipboardId);
  }

  onClipboardSelect(id: number) {
    this.selectClipboard(id);
  }

  onClipboardDelete(id: number) {
    const clipboard = this.clipboards$().find(c => c.id === id);
    const hasItems = this.selectedClipboardId() === id && this.items$().length > 0;
    const unfinishedCount = this.selectedClipboardId() === id ? this.unfinishedItemsCount() : 0;
    
    let message = 'Are you sure you want to delete this clipboard?';
    if (hasItems) {
      message = unfinishedCount > 0
        ? `Are you sure you want to delete this clipboard? All items in it will be deleted (${unfinishedCount} unfinished).`
        : 'Are you sure you want to delete this clipboard? All items in it will be deleted.';
    }
    
    if (!confirm(message)) {
      return;
    }

    this.dataSource.removeClipboard(id).subscribe({
      next: () => {
        this.snackbar.openSnackBar('Clipboard deleted successfully', 'Close');
        this.clipboards$.set(this.clipboards$().filter(c => c.id !== id));
        
        if (this.selectedClipboardId() === id) {
          const remainingClipboards = this.clipboards$();
          if (remainingClipboards.length > 0) {
            this.router.navigate(['/clipboard', remainingClipboards[0].id], {
              queryParams: { filter: this.filter(), page: 1 }
            });
          } else {
            this.router.navigate(['/']);
          }
        }
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error deleting clipboard', 'Close', true);
        console.error('Error deleting clipboard:', error);
      }
    });
  }

  onClipboardEdit(event: { id: number; name: string }) {
    const { id, name: newName } = event;
    this.editedClipboardName.set(newName);
  }

  onClipboardNameChange(newName: string) {
    this.editedClipboardName.set(newName);
  }

  onEditingClipboardChange(id: number | null) {
    this.editingClipboardId.set(id);
    
    // Initialize the edited name when editing starts
    if (id !== null) {
      const clipboard = this.clipboards$().find(c => c.id === id);
      if (clipboard) {
        this.editedClipboardName.set(clipboard.name);
      }
    } else {
      this.editedClipboardName.set('');
    }
  }

  onSaveClipboard() {
    const editingId = this.editingClipboardId();
    if (editingId === null) return;
    
    const newName = this.editedClipboardName();
    if (!newName || newName.trim() === '') return;

    this.dataSource.editClipboard(editingId, newName).subscribe({
      next: () => {
        this.snackbar.openSnackBar('Clipboard updated successfully', 'Close');
        this.clipboards$.set(
          this.clipboards$().map(c => 
            c.id === editingId ? { ...c, name: newName } : c
          )
        );
        this.editingClipboardId.set(null);
        this.editedClipboardName.set('');
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error updating clipboard', 'Close', true);
        console.error('Error editing clipboard:', error);
      }
    });
  }

  onAddClipboard(event: SubmitEvent) {
    event.preventDefault();
    
    if (this.newClipboardForm.name().invalid()) {
      this.newClipboardForm.name().markAsTouched();
      return;
    }

    const name = this.newClipboardForm.name().value();
    
    // Validate that the trimmed name is not empty
    if (name.trim().length === 0) {
      this.snackbar.openSnackBar('Clipboard name cannot be only whitespace', 'Close', true);
      return;
    }
    
    this.dataSource.addClipboard(name).subscribe({
      next: (clipboard: any) => {
        this.snackbar.openSnackBar('Clipboard added successfully', 'Close');
        this.clipboards$.set([...this.clipboards$(), clipboard]);
        this.resetClipboardForm();
        this.selectClipboard(clipboard.id);
      },
      error: (error: HttpErrorResponse) => {
        this.snackbar.openSnackBar('Error adding clipboard', 'Close', true);
        console.error('Error adding clipboard:', error);
      }
    });
  }

  resetClipboardForm(): void {
    this.newClipboardModel.set({
      name: ' ',
    });
    this.newClipboardForm.name().markAsDirty();
  }
}
