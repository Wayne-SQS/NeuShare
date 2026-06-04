export interface ModelPrice {
  id: number
  name: string
  provider: string
  inputPrice: number
  outputPrice: number
  priceUnit: string
  contextWindow: number
  speed: number
  coding: number
  reasoning: number
  chinese: number
  overall: number
  free: boolean
  note: string
}
