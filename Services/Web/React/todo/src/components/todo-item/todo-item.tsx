import { useState, useRef, useEffect } from 'react';
import './todo-item.css';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import EditIcon from '@mui/icons-material/Edit';
import UndoIcon from '@mui/icons-material/Undo';
import DeleteIcon from '@mui/icons-material/Delete';

interface ITodoItem {
  id: number;
  clipboardId: number;
  name: string;
  isComplete: boolean;
}

interface TodoItemProps {
  item: ITodoItem;
  editingItemId: number | null;
  onComplete: (id: number) => void;
  onEdit: (id: number) => void;
  onCancelEdit: () => void;
  onSave: (id: number, name: string) => void;
  onDelete: (id: number) => void;
}

export function TodoItem({
  item,
  editingItemId,
  onComplete,
  onEdit,
  onCancelEdit,
  onSave,
  onDelete
}: TodoItemProps) {
  const [editedName, setEditedName] = useState(item.name);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const isEditing = editingItemId === item.id;

  useEffect(() => {
    setEditedName(item.name);
    if (isEditing && textareaRef.current) {
      textareaRef.current.focus();
      // Auto-resize textarea
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = textareaRef.current.scrollHeight + 'px';
    }
  }, [isEditing, item.name]);

  const handleTextChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setEditedName(e.target.value);
    // Auto-resize textarea
    e.target.style.height = 'auto';
    e.target.style.height = e.target.scrollHeight + 'px';
  };

  const handleEdit = () => {
    if (isEditing) {
      setEditedName(item.name);
      onCancelEdit();
    } else {
      onEdit(item.id);
    }
  };

  const handleSave = () => {
    onSave(item.id, editedName);
  };

  const handleComplete = () => {
    onComplete(item.id);
  };

  const handleDelete = () => {
    onDelete(item.id);
  };

  const className = `app-todo-item${item.isComplete ? ' completed' : ''}${isEditing ? ' editing' : ''}`;

  return (
    <div className={className}>
      <textarea
        ref={textareaRef}
        readOnly={!isEditing}
        value={isEditing ? editedName : item.name}
        onChange={handleTextChange}
      />
      <div className="button-group">
        <button onClick={handleComplete} disabled={isEditing} title="Mark as complete">
          {item.isComplete ? (
            <CheckBoxIcon />
          ) : (
            <CheckBoxOutlineBlankIcon />
          )}
        </button>
        <button className="edit-btn" onClick={handleEdit} disabled={editingItemId !== null && !isEditing || item.isComplete} title={isEditing ? 'Undo' : 'Edit'}>
          {isEditing ? (
            <UndoIcon />
          ) : (
            <EditIcon />
          )}
        </button>
        <button className="delete-btn" onClick={handleDelete} title="Delete">
          <DeleteIcon />
        </button>
      </div>
      {isEditing && (
        <button className="save-button" onClick={handleSave} disabled={editedName === item.name}>
          Save
        </button>
      )}
    </div>
  );
}

export default TodoItem;