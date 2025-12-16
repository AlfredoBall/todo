interface IClipboardItem {
  id: number;
  name: string;
}

interface ITodoItem { // Use this later to define props or figure out something better than piggybacking
  id: number;
  clipboardId: number;
  name: string;
  isComplete: boolean;
}

const ItemFilter = {
  ALL: 'ALL',
  COMPLETED: 'COMPLETED',
  UNFINISHED: 'UNFINISHED',
} as const;

// Define the type using a union of the object's values
type ItemFilter = typeof ItemFilter[keyof typeof ItemFilter];

export type { IClipboardItem, ITodoItem, ItemFilter };