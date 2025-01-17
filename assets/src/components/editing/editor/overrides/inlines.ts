import { schema } from 'data/content/model';
import { Editor } from 'slate';

export const withInlines = (editor: Editor) => {
  editor.isInline = (element) => {
    try {
      const result = (schema as any)[element.type as string].isBlock;
      return !result;
    } catch (e) {
      return false;
    }
  };
  return editor;
};
