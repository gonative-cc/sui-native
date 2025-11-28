export function getProperty(key, obj, msg) {
  if (!(key in obj))
    throw new Error(
      "Wrong" + msg + ": " + key + ", must be in: " + Object.keys(obj),
    );
  return obj[key];
}
