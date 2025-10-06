import { useState } from "react";
import { Link } from "react-router";
import { validateForm } from "../utils/validateForm";
import "./styles/userEdit.css";

const AddUser = () => {
  const [errors, setErrors] = useState({});
  const [formData, setFormData] = useState({
    name: "",
    displayName: "",
    email: "",
    phone: "",
    address: "",
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    const validationErrors = validateForm(formData);

    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setErrors({});
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  return (
    <div className="user-edit-card">
      <h3>Add User</h3>
      <form onSubmit={handleSubmit}>
        <div className="section">
          <label htmlFor="name">
            Full Name <span className="asterisk">*</span>
          </label>
          <input
            type="text"
            name="name"
            id="name"
            value={formData.name}
            className={errors.name ? "error" : ""}
            onChange={(e) => handleInputChange(e)}
          />
          {errors.name && <span className="error-text">{errors.name}</span>}

          <label htmlFor="displayName">
            Display Name <span className="asterisk">*</span>
          </label>
          <input
            name="displayName"
            id="displayName"
            value={formData.displayName}
            className={errors.displayName ? "error" : ""}
            onChange={(e) => handleInputChange(e)}
          />
          {errors.displayName && (
            <span className="error-text">{errors.displayName}</span>
          )}

          <label htmlFor="email">
            Email<span className="asterisk">*</span>
          </label>
          <input
            name="email"
            id="email"
            className={errors.email ? "error" : ""}
            value={formData.email}
            onChange={(e) => handleInputChange(e)}
          />
          {errors.email && <span className="error-text">{errors.email}</span>}

          <label htmlFor="phone">
            Phone <span className="asterisk">*</span>
          </label>
          <input
            name="phone"
            id="phone"
            className={errors.phone ? "error" : ""}
            value={formData.phone}
            onChange={(e) => handleInputChange(e)}
          />
          {errors.phone && <span className="error-text">{errors.phone}</span>}
        </div>

        <div className="section">
          <label htmlFor="address">
            Address <span className="asterisk">*</span>
          </label>
          <textarea
            id="address"
            name="address"
            value={formData.address}
            className={errors.address ? "error" : ""}
            onChange={(e) => handleInputChange(e)}
          />
          {errors.address && (
            <span className="error-text">{errors.address}</span>
          )}
        </div>

        <div className="actions">
          <button type="submit">Save</button>
          <Link to="/" style={{ padding: "10px" }}>
            Back to List
          </Link>
        </div>
      </form>
    </div>
  );
};

export default AddUser;