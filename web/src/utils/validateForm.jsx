import { ERROR_MESSAGES } from "./constants";

export const validateForm = (formData) => {
  const newErrors = {};
  if (!formData.name.trim()) {
    newErrors.name = ERROR_MESSAGES.name.required;
  } else if (!/^[A-Za-z\s]+$/.test(formData.name)) {
    newErrors.name = ERROR_MESSAGES.name.invalid;
  }

  if (!formData.displayName.trim()) {
    newErrors.displayName = ERROR_MESSAGES.displayName.required;
  }

  if (!formData.email.trim()) {
    newErrors.email = ERROR_MESSAGES.email.required;
  } else if (!/^\S+@\S+\.\S+$/.test(formData.email)) {
    newErrors.email = ERROR_MESSAGES.email.invalid;
  }

  if (!formData.phone.trim()) {
    newErrors.phone = ERROR_MESSAGES.phone.required;
  } else if (!/^\d{10}$/.test(formData.phone)) {
    newErrors.phone = ERROR_MESSAGES.phone.invalid;
  }

  if (!formData.address.trim()) {
    newErrors.address = ERROR_MESSAGES.address.required;
  }

  return newErrors;
};
