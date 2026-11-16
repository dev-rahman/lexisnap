// Store assembly: combines slices + the RTK Query API, with redux-persist
// keeping prefs + streak in localStorage across reloads. Instantiated once on
// the client (see StoreProvider).

import { combineReducers, configureStore } from "@reduxjs/toolkit";
import {
  FLUSH,
  PAUSE,
  PERSIST,
  PURGE,
  REGISTER,
  REHYDRATE,
  persistReducer,
  persistStore,
} from "redux-persist";
import createWebStorage from "redux-persist/lib/storage/createWebStorage";

import { decksApi } from "./api/decksApi";
import auth from "./slices/authSlice";
import prefs from "./slices/prefsSlice";
import scan from "./slices/scanSlice";
import shell from "./slices/shellSlice";
import streak from "./slices/streakSlice";

// redux-persist touches localStorage, which doesn't exist during SSR — fall
// back to a no-op store on the server so imports don't throw.
function createNoopStorage() {
  return {
    getItem: (_key: string) => Promise.resolve(null),
    setItem: (_key: string, value: string) => Promise.resolve(value),
    removeItem: (_key: string) => Promise.resolve(),
  };
}

const storage =
  typeof window !== "undefined"
    ? createWebStorage("local")
    : createNoopStorage();

const rootReducer = combineReducers({
  prefs,
  streak,
  auth,
  shell,
  scan,
  [decksApi.reducerPath]: decksApi.reducer,
});

const persistedReducer = persistReducer(
  {
    key: "lexisnap",
    version: 1,
    storage,
    whitelist: ["prefs", "streak"], // auth/scan/shell are ephemeral
  },
  rootReducer,
);

export function makeStore() {
  const store = configureStore({
    reducer: persistedReducer,
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware({
        serializableCheck: {
          ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
        },
      }).concat(decksApi.middleware),
  });
  const persistor = persistStore(store);
  return { store, persistor };
}

export type AppStore = ReturnType<typeof makeStore>["store"];
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
