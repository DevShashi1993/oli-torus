import { combineReducers } from '@reduxjs/toolkit';
import activitiesReducer, { ActivitiesSlice } from '../../delivery/store/features/activities/slice';
import groupsReducer, { GroupsSlice } from '../../delivery/store/features/groups/slice';
import appReducer, { AppSlice } from './app/slice';
import pageReducer, { PageSlice } from './page/slice';
import partsReducer, { PartsSlice } from './parts/slice';

const rootReducer = combineReducers({
  [AppSlice]: appReducer,
  [PageSlice]: pageReducer,
  [PartsSlice]: partsReducer,
  [GroupsSlice]: groupsReducer,
  [ActivitiesSlice]: activitiesReducer,
});

export type RootState = ReturnType<typeof rootReducer>;

export default rootReducer;
