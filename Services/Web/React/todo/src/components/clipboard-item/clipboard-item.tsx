import './clipboard-item.css';
import { useState, useRef, useEffect } from 'react';
import EditIcon from '@mui/icons-material/Edit';
import UndoIcon from '@mui/icons-material/Undo';
import DeleteIcon from '@mui/icons-material/Delete';

interface ClipboardItemProps {
  id: number;
  name: string;
  isSelected?: boolean;
  editingClipboardId: number | null;
  onDelete: (id: number) => void;
  onEditingChange: (id: number | null) => void;
  onNameChange: (id: number, name: string) => void;
}

export function ClipboardItem({
  id,
  name,
  isSelected = false,
  editingClipboardId,
  onDelete,
  onEditingChange,
  onNameChange
}: ClipboardItemProps) {
  const [isEditing, setIsEditing] = useState(false);
  const nameInputRef = useRef<HTMLInputElement>(null);

  // Sync local editing state with the parent's editingClipboardId
  useEffect(() => {
    if (editingClipboardId !== id && isEditing) {
      setIsEditing(false);
    }
  }, [editingClipboardId, id, isEditing]);

  const handleEdit = () => {
    // Start editing
    setIsEditing(true);
    onEditingChange(id);
    setTimeout(() => {
      if (nameInputRef.current) {
        nameInputRef.current.focus();
        nameInputRef.current.select();
      }
    }, 0);
  };

  const handleCancel = () => {
    setIsEditing(false);
    onEditingChange(null);
    if (nameInputRef.current) {
      nameInputRef.current.value = name;
    }
  };

  const handleDelete = () => {
    onDelete(id);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Escape') {
      setIsEditing(false);
      onEditingChange(null);
      if (nameInputRef.current) {
        nameInputRef.current.value = name;
      }
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onNameChange(id, e.target.value);
  };

  return (
    <div className={`clipboard-item${isSelected ? ' selected' : ''}${isEditing ? ' editing' : ''}`}>
      <div className="clipboard-content">
        <div className="clipboard-name-container">
          <input
            ref={nameInputRef}
            type="text"
            defaultValue={name}
            readOnly={!isEditing}
            className="clipboard-name"
            onKeyDown={handleKeyDown}
            onChange={handleChange}
          />
        </div>
        <div className="clipboard-actions">
          <button
            type="button"
            onClick={isEditing ? handleCancel : handleEdit}
            className="edit-btn"
            disabled={editingClipboardId !== null && editingClipboardId !== id}
          >
            {isEditing ? <UndoIcon /> : <EditIcon />}
          </button>
          <button
            type="button"
            onClick={handleDelete}
            className="delete-btn"
          >
            <DeleteIcon />
          </button>
        </div>
      </div>
    </div>
  );
}