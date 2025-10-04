// components/ConfirmModal.js
import React from "react";

const ConfirmModal = ({ isOpen, onClose, onConfirm, message }) => {
  if (!isOpen) return null;

  return (
    <div style={styles.overlay}>
      <div style={styles.modal}>
        {/* Header */}
        <div style={styles.header}>
          <h3 style={{ margin: 0 }}>Confirmation</h3>
        </div>

        {/* Body */}
        <div style={styles.body}>
          <p>{message || "Are you sure?"}</p>
        </div>
        {/* Footer */}
        <div style={styles.footer}>
          <button
            style={{ ...styles.button, ...styles.confirmBtn }}
            onClick={onConfirm}
          >
            Yes
          </button>
          <button
            style={{ ...styles.button, ...styles.cancelBtn }}
            onClick={onClose}
          >
            No
          </button>
        </div>
      </div>
    </div>
  );
};

const styles = {
  overlay: {
    position: "fixed",
    top: 0,
    left: 0,
    width: "100vw",
    height: "100vh",
    backgroundColor: "rgba(0,0,0,0.5)",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    // zIndex: 999
  },
  modal: {
    backgroundColor: "#fff",
    padding: 20,
    borderRadius: 8,
    textAlign: "center",
  },
  header: {
    // backgroundColor: "#f5f5f5",
    padding: "15px 20px",
    borderBottom: "1px solid #ddd",
    color: "#333",
  },
  body: {
    padding: "20px",
    fontSize: "16px",
    color: "#333",
  },
  footer: {
    padding: "15px 20px",
    borderTop: "1px solid #ddd",
    display: "flex",
    justifyContent: "flex-end",
    gap: "10px",
  },
  button: {
    padding: "8px 16px",
    borderRadius: 4,
    border: "none",
    fontSize: "14px",
    cursor: "pointer",
    fontWeight: "bold",
  },
  confirmBtn: {
    backgroundColor: "red",
    color: "#fff",
  },
  cancelBtn: {
    backgroundColor: "#ccc",
    color: "#333",
  },
};

export default ConfirmModal;
