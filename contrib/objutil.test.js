import { describe, it, expect } from "bun:test";

import { getProperty } from "./objutil";

describe("getProperty", () => {
  const sampleObject = {
    name: "Alice",
    age: 30,
    city: "Wonderland",
    details: {
      nested: true,
    },
    occupation: undefined, // key exists, but value is undefined
  };
  const errorMessage = " object property";

  // Test case 1: Should return the correct value for an existing property.
  it("should return the value when the key exists in the object", () => {
    expect(getProperty("name", sampleObject, errorMessage)).toBe("Alice");
    expect(getProperty("age", sampleObject, errorMessage)).toBe(30);
  });

  // Test case 2: Should return the correct object for a nested property.
  it("should return a nested object if it is the value", () => {
    expect(getProperty("details", sampleObject, errorMessage)).toEqual({
      nested: true,
    });
  });

  // Test case 3: Should correctly handle keys with undefined values.
  it("should return undefined if the key exists but its value is undefined", () => {
    expect(
      getProperty("occupation", sampleObject, errorMessage),
    ).toBeUndefined();
  });

  // Test case 4: Should throw an error if the key does not exist.
  it("should throw an error when the key does not exist", () => {
    // We wrap the function call in a lambda to test if it throws.
    expect(() => {
      getProperty("country", sampleObject, errorMessage);
    }).toThrow();
  });

  // Test case 5: Should throw an error with a specific and informative message.
  it("should throw an error with the correct custom message", () => {
    const missingKey = "country";
    const expectedKeys = Object.keys(sampleObject).join(",");
    const expectedErrorMessage = `Wrong${errorMessage}: ${missingKey}, must be in: ${expectedKeys}`;

    expect(() => {
      getProperty(missingKey, sampleObject, errorMessage);
    }).toThrow(expectedErrorMessage);
  });

  // Test case 6: Should throw an error when given an empty object.
  it("should throw an error when the object is empty", () => {
    expect(() => {
      getProperty("anyKey", {}, errorMessage);
    }).toThrow("Wrong object property: anyKey, must be in: ");
  });
});
