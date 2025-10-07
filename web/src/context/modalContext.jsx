import { createContext, useContext, useState } from "react";

export const ModalContext = createContext();

export const ModalProvider = ({ children }) => {
  const [modalState, setModalState] = useState(null);

  const openConfirm = (message, onConfirm) => {
    setModalState({ message, onConfirm });
  };

  const closeConfirm = () => setModalState(null);

  const confirm = () => {
    modalState?.onConfirm?.();
    closeConfirm();
  };

  return (
    <ModalContext.Provider
      value={{
        isOpen: !!modalState,
        message: modalState?.message || "Are you sure?",
        openConfirm,
        closeConfirm,
        confirm,
      }}
    >
      {children}
    </ModalContext.Provider>
  );
};

export const useModal = () => {
  const context = useContext(ModalContext);
  if (!context) {
    throw new Error("useModal must be used within a ModalProvider");
  }
  return context;
};
