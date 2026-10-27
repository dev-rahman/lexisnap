import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { RouterProvider } from "react-router-dom";
import { PersistGate } from "redux-persist/integration/react";

import { router } from "@/router";
import { AuthListener } from "@/providers/AuthListener";
import { I18nProvider } from "@/providers/I18nProvider";
import { ThemeApplier } from "@/providers/ThemeApplier";
import { ToastHost } from "@/components/ui/ToastHost";
import { FullPageSpinner } from "@/components/ui/Spinner";
import { makeStore } from "@/store";
import { initDemoFromUrl } from "@/lib/demo";
import "@/styles/globals.css";

initDemoFromUrl();
const { store, persistor } = makeStore();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Provider store={store}>
      <PersistGate loading={<FullPageSpinner />} persistor={persistor}>
        <I18nProvider>
          <ThemeApplier />
          <AuthListener />
          <RouterProvider router={router} />
          <ToastHost />
        </I18nProvider>
      </PersistGate>
    </Provider>
  </StrictMode>,
);
