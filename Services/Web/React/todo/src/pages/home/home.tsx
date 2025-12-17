
import { useEffect, useState, useActionState } from 'react';
import './home.css';
import classNames from 'classnames';
import { type ITodoItem, type IClipboardItem, type ItemFilter } from '../../types';
import ApiService from '../../services/api';
import TodoItem from '../../components/todo-item/todo-item';
import { useSearchParams } from 'react-router-dom';
import { useSnackbar } from '../../components/snackbar/snackbar';
import { Paging } from '../../components/paging/paging';
import { ClipboardItem } from '../../components/clipboard-item/clipboard-item';
import { useMsal } from '@azure/msal-react';

const apiService = new ApiService();

function Home() {
  const { instance, accounts } = useMsal();
  const [clipboards, setClipboards] = useState<IClipboardItem[]>([]);
  const [items, setItems] = useState<ITodoItem[]>([]);
  const [selectedClipboardId, setSelectedClipboardId] = useState<number | null>(null);
  const [selectedItemFilter, setSelectedItemFilter] = useState<ItemFilter>('ALL');
  const [editingItemId, setEditingItemId] = useState<number | null>(null);
  const [editingClipboardId, setEditingClipboardId] = useState<number | null>(null);
  const [editedClipboardName, setEditedClipboardName] = useState<string>('');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const itemsPerPage = 10;
  const [searchParams, setSearchParams] = useSearchParams();
  const showSnackbar = useSnackbar();

  // Set MSAL instance and fetch clipboards when instance is ready or authentication changes
  useEffect(() => {
    apiService.setMsalInstance(instance);
    apiService.fetchClipboards().then(setClipboards);
  }, [instance, accounts]);

  // Load items after clipboards are available or when URL params change
  useEffect(() => {
    const clipboardParam = searchParams.has('clipboard') ? Number(searchParams.get('clipboard')) : null;
    const itemFilterParam = searchParams.has('itemFilter') ? searchParams.get('itemFilter') : 'ALL';
    const pageParam = searchParams.has('page') ? Number(searchParams.get('page')) : 1;

    setSelectedClipboardId(clipboardParam);
    setSelectedItemFilter(itemFilterParam as ItemFilter);
    setCurrentPage(pageParam > 0 ? pageParam : 1);

    var clipbloardId = clipboardParam ?? (clipboards.length > 0 ? clipboards[0].id : null);

    if (clipboardParam === null && clipboards.length > 0) {
      setSearchParams(`?clipboard=${clipboards[0].id}`);
    }

    if (clipbloardId !== null) {
      apiService.fetchItems(clipbloardId).then(setItems);
    }
  }, [clipboards, searchParams]);

  const filteredItems = items.filter(item => {
    if (selectedItemFilter === 'ALL') return true;
    if (selectedItemFilter === 'COMPLETED') return item.isComplete;
    if (selectedItemFilter === 'UNFINISHED') return !item.isComplete;
    return true;
  });

  const totalPages = Math.ceil(filteredItems.length / itemsPerPage);
  
  const pagedItems = filteredItems.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const changeClipboard = (clipboardId: number) => {
    console.log('Selected clipboard ID:', clipboardId);
    setSelectedClipboardId(clipboardId);
    setCurrentPage(1);
    const newSearchParams = new URLSearchParams(searchParams);
    newSearchParams.set('clipboard', clipboardId.toString());
    newSearchParams.delete('page'); // Reset to page 1 when changing clipboards
    setSearchParams(newSearchParams, { replace: true });

    apiService.fetchItems(clipboardId).then(setItems);
  }

  const changeItemFilter = (itemFilter: ItemFilter) => {
    setSelectedItemFilter(itemFilter);
    setCurrentPage(1);
    const newSearchParams = new URLSearchParams(searchParams);
    newSearchParams.set('itemFilter', itemFilter);
    newSearchParams.delete('page'); // Reset to page 1
    setSearchParams(newSearchParams, { replace: true });
  }

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
    const newSearchParams = new URLSearchParams(searchParams);
    if (page > 1) {
      newSearchParams.set('page', page.toString());
    } else {
      newSearchParams.delete('page');
    }
    setSearchParams(newSearchParams, { replace: true });
  }

  const hasClipboards = () => {
    return clipboards.length > 0;
  }

  const clipboardSelectorCls = classNames('clipboard-selector', {
    'disabled': !hasClipboards(),
  })

  const itemsSectionCls = classNames('items-section', {
    'disabled': !hasClipboards(),
  })

  const handleTodoItemComplete = (id: number) => {
    const item = items.find(i => i.id === id);
    if (!item) return;

    if (!item.isComplete) {
      apiService.completeItem(id)
      .then((response) => {
        if (!response.ok) {
          console.error('Error completing item:', response);
          showSnackbar('Failed to complete item', { isError: true });
          return;
        }
        setItems(items.map(i => 
          i.id === id ? { ...i, isComplete: !i.isComplete } : i
        ));
        showSnackbar('Item completed successfully!');
      })
      .catch((error) => {
        console.error('Error completing item:', error);
        showSnackbar('Failed to complete item', { isError: true });
      });
    } else {
      apiService.unfinishItem(id)
      .then((response) => {
        if (!response.ok) {
          console.error('Error setting item as unfinished:', response);
          showSnackbar('Failed to set item as unfinished', { isError: true });
          return;
        }
        setItems(items.map(i => 
          i.id === id ? { ...i, isComplete: !i.isComplete } : i
        ));
        showSnackbar('Item set to unfinished.');
      })
      .catch((error) => {
        console.error('Error setting item as unfinished:', error);
        showSnackbar('Failed to set item as unfinished', { isError: true });
      });
    }
  };

  const handleTodoItemDelete = (id: number) => {
    apiService.deleteItem(id)
    .then((response) => {
      if (!response.ok) {
        console.error('Error deleting item:', response);
        showSnackbar('Failed to delete item', { isError: true });
        return;
      }
      setItems(items.filter(i => i.id !== id));
      // Clear editing state if the deleted item was being edited
      if (editingItemId === id) {
        setEditingItemId(null);
      }
      showSnackbar('Item deleted successfully!');
    })
    .catch((error) => {
      console.error('Error deleting item:', error);
      showSnackbar('Failed to delete item', { isError: true });
    });
  };

  const handleTodoItemSave = (id: number, name: string) => {
    apiService.editItem(id, name)
    .then((response) => {
      if (!response.ok) {
        console.error('Error updating item:', response);
        showSnackbar('Failed to update item', { isError: true });
        return;
      }
      setItems(items.map(i => 
        i.id === id ? { ...i, name } : i
      ));
      setEditingItemId(null);
      showSnackbar('Item updated successfully!');
    })
    .catch((error) => {
      console.error('Error updating item:', error);
      showSnackbar('Failed to update item', { isError: true });
    });
  };

  const handleTodoItemEdit = (id: number) => {
    setEditingItemId(id);
  };

  const handleTodoItemCancelEdit = () => {
    setEditingItemId(null);
  };

  const handleClipboardDelete = (id: number) => {
    const hasItems = selectedClipboardId === id && items.length > 0;
    const unfinishedCount = selectedClipboardId === id ? items.filter(item => !item.isComplete).length : 0;
    
    // This messaging can be improved further by retrieving item count for the clipboard to be deleted without loading all items
    let message = 'Are you sure you want to delete this clipboard?';
    if (hasItems) {
      message = unfinishedCount > 0
        ? `Are you sure you want to delete this clipboard? All items in it will be deleted (${unfinishedCount} unfinished).`
        : 'Are you sure you want to delete this clipboard? All items in it will be deleted.';
    }
    
    if (!window.confirm(message)) {
      return;
    }

    apiService.deleteClipboard(id)
      .then((response) => {
        if (!response.ok) {
          console.error('Error deleting clipboard:', response);
          showSnackbar('Failed to delete clipboard', { isError: true });
          return;
        }
        
        // Clear editing state if the deleted clipboard was being edited
        if (editingClipboardId === id) {
          setEditingClipboardId(null);
          setEditedClipboardName('');
        }
        
        const updatedClipboards = clipboards.filter(c => c.id !== id);
        
        // Clear items immediately to prevent showing stale data
        if (selectedClipboardId === id) {
          setItems([]);
        }
        
        // Update URL and clipboards state - let useEffect handle fetching
        if (selectedClipboardId === id) {
          const newSearchParams = new URLSearchParams(searchParams);
          
          if (updatedClipboards.length > 0) {
            // Select the first clipboard and update URL
            const firstClipboardId = updatedClipboards[0].id;
            setSelectedClipboardId(firstClipboardId);
            newSearchParams.set('clipboard', firstClipboardId.toString());
            setSearchParams(newSearchParams, { replace: true });
          } else {
            // No clipboards left
            setSelectedClipboardId(null);
            newSearchParams.delete('clipboard');
            setSearchParams(newSearchParams, { replace: true });
          }
        }
        
        // Update clipboards state - this will trigger useEffect to fetch items
        setClipboards(updatedClipboards);
        
        showSnackbar('Clipboard deleted successfully!');
      })
      .catch((error) => {
        console.error('Error deleting clipboard:', error);
        showSnackbar('Failed to delete clipboard', { isError: true });
      });
  };

  const handleClipboardNameChange = (id: number, name: string) => {
    setEditedClipboardName(name);
  };

  const handleClipboardSave = (id: number, name: string) => {
    apiService.editClipboard(id, name)
      .then((response) => {
        if (!response.ok) {
          console.error('Error updating clipboard:', response);
          showSnackbar('Failed to update clipboard', { isError: true });
          return;
        }
        setClipboards(clipboards.map(c => c.id === id ? { ...c, name } : c));
        showSnackbar('Clipboard updated successfully!');
        setEditingClipboardId(null);
        setEditedClipboardName('');
      })
      .catch((error) => {
        console.error('Error updating clipboard:', error);
        showSnackbar('Failed to update clipboard', { isError: true });
      });
  };

  // Todo form action
  const addTodoItemAction = async (_prevState: any, formData: FormData) => {
    const name = formData.get('name') as string;

    // Validate clipboard is selected
    if (!selectedClipboardId) {
      return { success: false, error: 'Please select a clipboard first' };
    }

    // Validate name is not empty or whitespace
    if (!name || name.trim().length === 0) {
      return { success: false, error: 'Todo item name is required and cannot be only whitespace' };
    }

    try {
      const response = await apiService.addItem(selectedClipboardId, name);
      
      if (!response.ok) {
        console.error('Error adding item:', response);
        showSnackbar('Failed to add item', { isError: true });
        return { success: false, error: 'Failed to add item. Please try again.' };
      }

      const newItem = await response.json();
      
      // Update items list
      setItems([...items, newItem]);

      showSnackbar('Item added successfully!');
      return { success: true, error: null };
    } catch (error) {
      console.error('Error adding item:', error);
      showSnackbar('Failed to add item', { isError: true });
      return { success: false, error: 'Failed to add item. Please try again.' };
    }
  };

  const [formState, formAction, isPending] = useActionState(addTodoItemAction, { success: false, error: null });

  // Clipboard form action
  const addClipboardAction = async (_prevState: any, formData: FormData) => {
    const name = formData.get('name') as string;

    // Validate name is not empty or whitespace
    if (!name || name.trim().length === 0) {
      return { success: false, error: 'Clipboard name is required and cannot be only whitespace' };
    }

    return apiService.addClipboard(name)
      .then(async (response) => {
        if (!response.ok) {
          console.error('Error adding clipboard:', response);
          showSnackbar('Failed to add clipboard', { isError: true });
          return Promise.resolve({ success: false, error: 'Failed to add clipboard. Please try again.' });
        }

        const newClipboard = await response.json();
        // Update clipboards list
        setClipboards([...clipboards, newClipboard]);
        // Select the new clipboard
        setSelectedClipboardId(newClipboard.id);
        const newSearchParams = new URLSearchParams(searchParams);
        newSearchParams.set('clipboard', newClipboard.id.toString());
        setSearchParams(newSearchParams, { replace: true });
        // Load items for the new clipboard
        apiService.fetchItems(newClipboard.id).then(setItems);
        showSnackbar('Clipboard added successfully!');
        return { success: true, error: null };
      })
      .catch((error) => {
        console.error('Error adding clipboard:', error);
        showSnackbar('Failed to add clipboard', { isError: true });
        return { success: false, error: 'Failed to add clipboard. Please try again.' };
      });
  };

  const [clipboardFormState, clipboardFormAction, isClipboardPending] = useActionState(addClipboardAction, { success: false, error: null });

  return (
    <>
      <div className="home-container">
        <h1>Todo List</h1>

          <div className={clipboardSelectorCls}>
            <label>
              Select Clipboard:
              <select disabled={!hasClipboards()} value={selectedClipboardId ?? ''} onChange={(e) => changeClipboard(Number(e.target.value))}>
                {clipboards.map((clipboard: IClipboardItem) => (
                  <option
                    key={clipboard.id}
                    value={clipboard.id}
                  >
                    {clipboard.name}
                  </option>
                ))
                }
              </select>
            </label>
          </div>

          <div className={itemsSectionCls}>
            <div className="filter-buttons">
              <button 
                onClick={() => changeItemFilter('ALL')}
                className={selectedItemFilter === 'ALL' ? 'active' : ''}
              >
                All {items.length}
              </button>
              <button 
                onClick={() => changeItemFilter('UNFINISHED')}
                className={selectedItemFilter === 'UNFINISHED' ? 'active' : ''}
              >
                Unfinished {items.filter(item => !item.isComplete).length}
              </button>
              <button 
                onClick={() => changeItemFilter('COMPLETED')}
                className={selectedItemFilter === 'COMPLETED' ? 'active' : ''}
              >
                Completed {items.filter(item => item.isComplete).length}
              </button>
            </div>

            {pagedItems.map((item: ITodoItem) => (
              <TodoItem
                key={item.id}
                item={item}
                editingItemId={editingItemId}
                onComplete={handleTodoItemComplete}
                onEdit={handleTodoItemEdit}
                onCancelEdit={handleTodoItemCancelEdit}
                onSave={handleTodoItemSave}
                onDelete={handleTodoItemDelete}
              />
            ))}

            <Paging
              currentPage={currentPage}
              totalPages={totalPages}
              onPageChange={handlePageChange}
            />
          </div>

          <div className="forms-container">
            <div className="new-todo-container">
              <form className="todo-form" action={formAction}>
                <div>
                  <label>To Do:</label>
                  <textarea name="name" disabled={!hasClipboards() || isPending}></textarea>
                  
                  {formState.error && (
                    <ul className="error-list">
                      <li>{formState.error}</li>
                    </ul>
                  )}
                </div>

                <button type="submit" disabled={!hasClipboards() || isPending}>
                  {isPending ? 'Adding...' : 'Add New Todo Item'}
                </button>
              </form>
            </div>
            <div className="clipboard-container">
              <label className="clipboard-label">Manage Clipboards:</label>
              <div className="clipboard-list">
                {clipboards.map((clipboard: any) => (
                  <ClipboardItem
                    key={clipboard.id}
                    id={clipboard.id}
                    name={clipboard.name}
                    isSelected={clipboard.id === selectedClipboardId}
                    editingClipboardId={editingClipboardId}
                    onEditingChange={setEditingClipboardId}
                    onDelete={handleClipboardDelete}
                    onNameChange={handleClipboardNameChange}
                  />
                ))}
              </div>
              <button 
                className="save-clipboard-button" 
                onClick={() => {
                  if (editingClipboardId !== null && editedClipboardName.trim()) {
                    handleClipboardSave(editingClipboardId, editedClipboardName.trim());
                  }
                }}
                style={{ display: editingClipboardId === null ? 'none' : 'block' }}
                disabled={!editedClipboardName.trim() || editedClipboardName === clipboards.find(c => c.id === editingClipboardId)?.name}
              >
                Save
              </button>

              <hr/>

              <form className="new-clipboard-form" action={clipboardFormAction}>
                <div>
                  <label>
                    New Clipboard Name:
                    <input type="text" name="name" disabled={isClipboardPending} />
                  </label>

                  {clipboardFormState.error && (
                    <ul className="error-list">
                      <li>{clipboardFormState.error}</li>
                    </ul>
                  )}
                </div>

                <button type="submit" disabled={isClipboardPending}>
                  {isClipboardPending ? 'Adding...' : 'Add Clipboard'}
                </button>
              </form>
            </div>
          </div>
      </div>
    </>
  )
}

export default Home;