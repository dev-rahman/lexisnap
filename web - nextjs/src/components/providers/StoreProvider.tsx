"use client";

import { useRef, type ReactNode } from "react";
import { Provider } from "react-redux";
import { PersistGate } from "redux-persist/integration/react";

import { makeStore, type AppStore } from "@/store";
import type { Persistor } from "redux-persist";

/** Creates the store once on the client and wraps the tree with persistence. */
export function StoreProvider({ children }: { children: ReactNode }) {
  const ref = useRef<{ store: AppStore; persistor: Persistor } | null>(null);
  if (!ref.current) {
    ref.current = makeStore();
  }

  return (
    <Provider store={ref.current.store}>
      <PersistGate loading={null} persistor={ref.current.persistor}>
        {children}
      </PersistGate>
    </Provider>
  );
}
