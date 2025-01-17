import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit';
import guid from 'utils/guid';
import { RootState } from '../../rootReducer';

export interface PageState {
  userId: number;
  userName: string;
  resourceId: number;
  sectionSlug: string;
  pageSlug: string;
  pageTitle: string;
  content: any; // TODO typing
  resourceAttemptState: any;
  resourceAttemptGuid: string;
  activityGuidMapping: any;
  previewMode: boolean;
  enableHistory: boolean;
  activityTypes: any[];
  score: number;
  graded: boolean;
}

const initialState: PageState = {
  userId: -1,
  userName: 'Guest',
  resourceId: -1,
  sectionSlug: '',
  pageSlug: '',
  pageTitle: '',
  content: null,
  resourceAttemptGuid: '',
  resourceAttemptState: {},
  activityGuidMapping: {},
  previewMode: false,
  enableHistory: false,
  activityTypes: [],
  score: 0,
  graded: false,
};

const pageSlice = createSlice({
  name: 'page',
  initialState,
  reducers: {
    loadPageState: (state, action: PayloadAction<PageState>) => {
      state.userId = action.payload.userId;
      state.userName = action.payload.userName || 'Guest';
      state.resourceId = action.payload.resourceId;
      state.pageSlug = action.payload.pageSlug;
      state.pageTitle = action.payload.pageTitle;
      state.sectionSlug = action.payload.sectionSlug;
      state.content = action.payload.content;
      state.enableHistory =
        action.payload?.content?.custom?.allowNavigation ||
        action.payload?.content?.custom?.enableHistory ||
        false;
      state.resourceAttemptGuid = action.payload.resourceAttemptGuid;
      state.resourceAttemptState = action.payload.resourceAttemptState;
      state.activityGuidMapping = action.payload.activityGuidMapping;
      state.previewMode = !!action.payload.previewMode;
      state.activityTypes = action.payload.activityTypes;
      state.graded = !!action.payload.graded;

      if (state.previewMode && !state.resourceAttemptGuid) {
        state.resourceAttemptGuid = `preview_${guid()}`;
      }
    },
    setScore(state, action: PayloadAction<{ score: number }>) {
      state.score = action.payload.score;
    },
  },
});

export const PageSlice = pageSlice.name;

export const { loadPageState, setScore } = pageSlice.actions;

export const selectState = (state: RootState): PageState => state[PageSlice];
export const selectSectionSlug = createSelector(selectState, (state) => state.sectionSlug);
export const selectPageTitle = createSelector(selectState, (state) => state.pageTitle);
export const selectPageSlug = createSelector(selectState, (state) => state.pageSlug);
export const selectPageContent = createSelector(selectState, (state) => state.content);
export const selectPreviewMode = createSelector(selectState, (state) => state.previewMode);
export const selectEnableHistory = createSelector(selectState, (state) => state.enableHistory);
export const selectResourceAttemptGuid = createSelector(
  selectState,
  (state) => state.resourceAttemptGuid,
);
export const selectNavigationSequence = (sequence: any[]) => {
  return sequence?.filter((entry: any) => !entry.custom?.isLayer && !entry.custom?.isBank);
};

export const selectActivityTypes = createSelector(selectState, (state) => state.activityTypes);
export const selectActivityGuidMapping = createSelector(
  selectState,
  (state: PageState) => state.activityGuidMapping,
);

export const selectUserName = createSelector(selectState, (state) => state.userName);

export const selectScore = createSelector(selectState, (state) => state.score);

export const selectIsGraded = createSelector(selectState, (state) => state.graded);

export default pageSlice.reducer;
