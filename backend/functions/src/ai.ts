import { AppError } from "./errors.js";
import type { GeneratePlanRequest } from "./schemas.js";

/**
 * AI provider abstraction (ADR-0001/0002: provider and cost limits behind an interface).
 * P3-02 ships only a stub; the Vertex AI implementation arrives with P3-05 (after P3-10).
 */
export interface PlanModel {
  generate(request: GeneratePlanRequest): Promise<never>;
}

export const stubModel: PlanModel = {
  generate(): Promise<never> {
    return Promise.reject(new AppError("not_implemented"));
  },
};
