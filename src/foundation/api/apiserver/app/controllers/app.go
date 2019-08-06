package controllers

import (
	"github.com/revel/revel"
)

type App struct {
	*revel.Controller
}

func (c App) Index() revel.Result {
	return c.Render()
}

// IecStatus represents the working status of IEC
// This structure is required by revel test cmd.
type IecStatus struct {
	Status         string
	Passed       bool
	// ErrorHTML    template.HTML
	// ErrorSummary string
}

func (c App) GetStatus() revel.Result {
	status := IecStatus{Status: "ok", Passed: true}
	return c.RenderJSON(status)
}
